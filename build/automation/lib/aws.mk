aws-session-fail-if-invalid: ### Fail if the AWS session variables are not set
	([ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]) \
		&& exit 1 ||:

aws-assume-role-export-variables: ### Get assume AWS role export for the Jenkins user - optional: PROFILE=[name]
	if [ $(AWS_ROLE) == $(AWS_ROLE_JENKINS) ]; then
		array=($$(
			make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
				$(AWSCLI) sts assume-role \
					--role-arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(AWS_ROLE) \
					--role-session-name $(AWS_ROLE_SESSION) \
					--output text \
					--query=Credentials.[AccessKeyId,SecretAccessKey,SessionToken] \
				| sed -E 's/[[:blank:]]+/ /g' \
			"
		))
		echo "export AWS_ACCESS_KEY_ID=$${array[0]}"
		echo "export AWS_SECRET_ACCESS_KEY=$${array[1]}"
		echo "export AWS_SESSION_TOKEN=$${array[2]}"
	fi

aws-account-check-id: ### Checked if user has MFA'd into the account - mandatory: ID; returns: true|false
	if [ $(ID) == "$$(make aws-account-get-id)" ] && [ "$$TEXAS_SESSION_EXPIRY_TIME" -gt $$(date -u +"%Y%m%d%H%M%S") ]; then
		echo true
	else
		echo false
	fi

aws-account-get-id: ### Get the account ID user has MFA'd into
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) sts get-caller-identity \
		--query 'Account' \
		--output text \
	" | tr -d '\r' | tr -d '\n'

aws-secret-create: ### Create a new AWS secret and save the value - mandatory: NAME=[secret name]; optional: VALUE=[string or file://file.json],AWS_REGION=[AWS region]
	if [ "false" == $$(make aws-secret-exists NAME=$(NAME)) ]; then
		make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
			$(AWSCLI) secretsmanager create-secret \
				--name $(NAME) \
				--region $(AWS_REGION) \
				--output text \
		"
	else
		echo "Secret '$(NAME)' already exists!"
	fi
	if [ -n "$(VALUE)" ]; then
		make aws-secret-put NAME=$(NAME) VALUE=$(VALUE) AWS_REGION=$(AWS_REGION)
	fi

aws-secret-put: ### Put AWS secret value in the specified secret - mandatory: NAME=[secret name],VALUE=[string or file://file.json]; optional: AWS_REGION=[AWS region]
	file=$$(echo $(VALUE) | grep -E "^file://" > /dev/null 2>&1 && echo $(VALUE) | sed 's;file://;;g' ||:)
	[ -n "$$file" ] && volume="--volume $$file:$$file" || mount=
	make -s docker-run-tools ARGS="$$volume $$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) secretsmanager put-secret-value \
			--secret-id $(NAME) \
			--secret-string "$(VALUE)" \
			--version-stage AWSCURRENT \
			--region $(AWS_REGION) \
			--output text \
	"

aws-secret-get: ### Get AWS secret - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) secretsmanager get-secret-value \
			--secret-id $(NAME) \
			--version-stage AWSCURRENT \
			--region $(AWS_REGION) \
			--output text \
			--query '{SecretString: SecretString}' \
	" | tr -d '\r' | tr -d '\n'

aws-secret-get-and-format: ### Get AWS secret - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]
	make aws-secret-get NAME=$(NAME) \
		| make -s docker-run-tools CMD="jq -r"

aws-secret-exists: ### Check if AWS secret exists - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]; returns: true|false
	count=$$(make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) secretsmanager list-secrets \
			--region $(AWS_REGION) \
			--output text \
			--query 'SecretList[*].Name' \
	" | grep $(NAME) | wc -l)
	[ 0 -eq $$count ] && echo false || echo true

aws-s3-create: ### Create secure bucket - mandatory: NAME=[bucket name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3api create-bucket \
			--bucket $(NAME) \
			--acl private \
			--create-bucket-configuration LocationConstraint=$(AWS_REGION) \
			--region $(AWS_REGION) \
	"
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3api put-public-access-block \
			--bucket $(NAME) \
			--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
	"
	json='{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-encryption \
			--bucket $(NAME) \
			--server-side-encryption-configuration '$$json' \
	"
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-versioning \
			--bucket $(NAME) \
			--versioning-configuration "Status=Enabled" \
	"
	json='TagSet=[{Key=Programme,Value=$(PROGRAMME)},{Key=Service,Value=$(TEXAS_SERVICE_TAG)},{Key=Environment,Value=$(PROFILE)}]'
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-tagging \
			--bucket $(NAME) \
			--tagging '$$json' \
	"

aws-s3-upload: ### Upload file to bucket - mandatory: FILE=[local path (inside container)],URI=[remote path]; optional: ARGS=[S3 cp options]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3 cp \
			$(FILE) \
			s3://$(URI) \
			$(ARGS) \
	"

aws-s3-download: ### Download file from bucket - mandatory: URI=[remote path],FILE=[local path (inside container)]; optional: ARGS=[S3 cp options]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3 cp \
			s3://$(URI) \
			$(FILE) \
			$(ARGS) \
	"

aws-s3-exists: ### Check if bucket exists - mandatory: NAME=[bucket name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) s3 ls \
			s3://$(NAME) \
		2>&1 | grep -q NoSuchBucket \
	" > /dev/null 2>&1 && echo false || echo true

aws-ecr-get-login-password: ### Get the ECR user login password
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) ecr get-login-password --region $(AWS_REGION) \
	"

aws-ses-verify-email-identity: ### Verify SES email address - mandatory: NAME
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=localstack' ||:)" CMD=" \
		$(AWSCLI) ses verify-email-identity \
			--email-address $(NAME) \
			--region $(AWS_SES_REGION) \
	"

# ==============================================================================

aws-get-elasticsearch-domain: ### Get AWS elastic search domain - mandatory: NAME; optional: AWS_REGION
	aws es describe-elasticsearch-domain \
		--domain-name $(NAME) \
		--region $(AWS_REGION) \
		--query 'DomainStatus.Endpoints.vpc' \
		--output text

aws-get-cognito-userpool-id: ### Get Cognito userpool ID - mandatory: NAME; optional: AWS_REGION
	aws cognito-idp list-user-pools \
		--query "UserPools[?Name=='$(NAME)'].Id" \
		--region $(AWS_REGION) \
		--max-results 60 \
		--output text

aws-get-cognito-client-id: ### Get Cognito client ID - mandatory: NAME; optional: AWS_REGION
	aws cognito-idp list-user-pool-clients \
		--user-pool-id $$(make -s aws-get-cognito-userpool-id NAME=$(NAME)) \
		--region $(AWS_REGION) \
		--query 'UserPoolClients[].ClientId' \
		--output text

aws-get-cognito-client-secret: ### Get Cognito client secret - mandatory: NAME; optional: AWS_REGION
	aws cognito-idp describe-user-pool-client \
		--user-pool-id $$(make -s aws-get-cognito-userpool-id NAME=$(NAME)) \
		--client-id $$(make -s aws-get-cognito-client-id NAME=$(NAME)) \
		--region $(AWS_REGION) \
		--query 'UserPoolClient.ClientSecret' \
		--output text

# ==============================================================================

.SILENT: \
	aws-account-check-id \
	aws-account-get-id \
	aws-assume-role-export-variables \
	aws-ecr-get-login-password \
	aws-s3-exists \
	aws-secret-create \
	aws-secret-exists \
	aws-secret-get \
	aws-secret-get-and-format \
	aws-secret-put
