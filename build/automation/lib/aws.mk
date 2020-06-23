aws-session-fail-if-invalid: ### Fail if the session variables are not set
	([ -z "$$AWS_ACCESS_KEY_ID" ] || [ -z "$$AWS_SECRET_ACCESS_KEY" ] || [ -z "$$AWS_SESSION_TOKEN" ]) \
		&& exit 1 ||:

aws-assume-role-export-variables: ### Get assume role export for the Jenkins user - optional: PROFILE=[name]
	if [ $(AWS_ROLE) == $(AWS_ROLE_JENKINS) ]; then
		array=($$(
			make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
				$(AWSCLI) sts assume-role \
					--role-arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(AWS_ROLE) \
					--role-session-name $(AWS_ROLE_SESSION) \
					--query=Credentials.[AccessKeyId,SecretAccessKey,SessionToken] \
					--output text \
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
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) sts get-caller-identity \
		--query 'Account' \
		--output text \
	" | tr -d '\r' | tr -d '\n'

aws-secret-create: ### Create a new secret and save the value - mandatory: NAME=[secret name]; optional: VALUE=[string or file://file.json],AWS_REGION=[AWS region]
	if [ "false" == $$(make aws-secret-exists NAME=$(NAME)) ]; then
		make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
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

aws-secret-put: ### Put secret value in the specified secret - mandatory: NAME=[secret name],VALUE=[string or file://file.json]; optional: AWS_REGION=[AWS region]
	file=$$(echo $(VALUE) | grep -E "^file://" > /dev/null 2>&1 && echo $(VALUE) | sed 's;file://;;g' ||:)
	[ -n "$$file" ] && volume="--volume $$file:$$file" || mount=
	make -s docker-run-tools ARGS="$$volume $$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) secretsmanager put-secret-value \
			--secret-id $(NAME) \
			--secret-string "$(VALUE)" \
			--version-stage AWSCURRENT \
			--region $(AWS_REGION) \
			--output text \
	"

aws-secret-get: ### Get secret - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) secretsmanager get-secret-value \
			--secret-id $(NAME) \
			--version-stage AWSCURRENT \
			--region $(AWS_REGION) \
			--query '{SecretString: SecretString}' \
			--output text \
	" | tr -d '\r' | tr -d '\n'

aws-secret-get-and-format: ### Get secret - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]
	make aws-secret-get NAME=$(NAME) \
		| make -s docker-run-tools CMD="jq -r"

aws-secret-exists: ### Check if secret exists - mandatory: NAME=[secret name]; optional: AWS_REGION=[AWS region]; returns: true|false
	count=$$(make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) secretsmanager list-secrets \
			--region $(AWS_REGION) \
			--query 'SecretList[*].Name' \
			--output text \
	" | grep $(NAME) | wc -l)
	[ 0 -eq $$count ] && echo false || echo true

aws-iam-policy-create: ### Create IAM policy - mandatory: NAME=[policy name],DESCRIPTION=[policy description],FILE=[path to json file]
	cp $(FILE) $(TMP_DIR_REL)/$(@).json
	make file-replace-variables FILE=$(TMP_DIR_REL)/$(@).json
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) iam create-policy \
			--policy-name $(NAME) \
			--policy-document file://$(TMP_DIR_REL)/$(@).json \
			--description '$(DESCRIPTION)' \
	"
	rm $(TMP_DIR_REL)/$(@).json

aws-iam-policy-exists: ### Check if IAM policy exists - mandatory: NAME=[policy name]; returns: true|false
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) iam get-policy \
			--policy-arn arn:aws:iam::$(AWS_ACCOUNT_ID):policy/$(NAME) \
	" > /dev/null 2>&1 && echo true || echo false

aws-iam-role-create: ### Create IAM role - mandatory: NAME=[role name],DESCRIPTION=[role description],FILE=[path to json file]
	cp $(FILE) $(TMP_DIR_REL)/$(@).json
	make file-replace-variables FILE=$(TMP_DIR_REL)/$(@).json
	tags='[{"Key":"Programme","Value":"$(PROGRAMME)"},{"Key":"Service","Value":"$(SERVICE_TAG)"},{"Key":"Environment","Value":"$(PROFILE)"}]'
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) iam create-role \
			--role-name $(NAME) \
			--assume-role-policy-document file://$(TMP_DIR_REL)/$(@).json \
			--description '$(DESCRIPTION)' \
			--tags '$$tags' \
	"
	rm $(TMP_DIR_REL)/$(@).json

aws-iam-role-exists: ### Check if IAM role exists - mandatory: NAME=[role name]; returns: true|false
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) iam get-role \
			--role-name $(NAME) \
	" > /dev/null 2>&1 && echo true || echo false

aws-iam-role-attach-policy: ### Attach IAM policy to role IAM role - mandatory: ROLE_NAME=[role name],POLICY_NAME=[policy name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) iam attach-role-policy \
			--role-name $(ROLE_NAME) \
			--policy-arn arn:aws:iam::$(AWS_ACCOUNT_ID):policy/$(POLICY_NAME) \
	"

aws-s3-create: ### Create secure bucket - mandatory: NAME=[bucket name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3api create-bucket \
			--bucket $(NAME) \
			--acl private \
			--create-bucket-configuration LocationConstraint=$(AWS_REGION) \
			--region $(AWS_REGION) \
	"
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3api put-public-access-block \
			--bucket $(NAME) \
			--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
	"
	json='{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-encryption \
			--bucket $(NAME) \
			--server-side-encryption-configuration '$$json' \
	"
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-versioning \
			--bucket $(NAME) \
			--versioning-configuration "Status=Enabled" \
	"
	tags='TagSet=[{Key=Programme,Value=$(PROGRAMME)},{Key=Service,Value=$(SERVICE_TAG)},{Key=Environment,Value=$(PROFILE)}]'
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3api put-bucket-tagging \
			--bucket $(NAME) \
			--tagging '$$tags' \
	"

aws-s3-upload: ### Upload file to bucket - mandatory: FILE=[local path (inside container)],URI=[remote path]; optional: ARGS=[S3 cp options]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3 cp \
			$(FILE) \
			s3://$(URI) \
			$(ARGS) \
	"

aws-s3-download: ### Download file from bucket - mandatory: URI=[remote path],FILE=[local path (inside container)]; optional: ARGS=[S3 cp options]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3 cp \
			s3://$(URI) \
			$(FILE) \
			$(ARGS) \
	"

aws-s3-exists: ### Check if bucket exists - mandatory: NAME=[bucket name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) s3 ls \
			s3://$(NAME) \
		2>&1 | grep -q NoSuchBucket \
	" > /dev/null 2>&1 && echo false || echo true

aws-rds-describe-instance: ### Describe RDS instance - mandatory: DB_INSTANCE
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) rds describe-db-instances \
			--region $(AWS_REGION) \
			--db-instance-identifier=$(DB_INSTANCE) \
	" | make -s docker-run-tools CMD="jq -r '.DBInstances[0]'"

aws-rds-create-snapshot: ### Create RDS instance snapshot - mandatory: DB_INSTANCE,SNAPSHOT_NAME
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		aws rds create-db-snapshot \
			--region $(AWS_REGION) \
			--db-instance-identifier $(DB_INSTANCE) \
			--db-snapshot-identifier $(SNAPSHOT_NAME) \
	"

aws-rds-get-snapshot-status: ### Get RDS snapshot status - mandatory: SNAPSHOT_NAME
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) rds describe-db-snapshots \
			--region $(AWS_REGION) \
			--db-snapshot-identifier $(SNAPSHOT_NAME) \
			--query 'DBSnapshots[].Status' \
			--output text \
	" | tr -d '\r' | tr -d '\n'

aws-rds-wait-for-snapshot: ### Wait for RDS snapshot to become available - mandatory: SNAPSHOT_NAME
	echo "Waiting for the snapshot to become available"
	count=0
	until [ $$count -ge 1800 ]; do
		if [ "$$(make aws-rds-get-snapshot-status SNAPSHOT_NAME=$(SNAPSHOT_NAME))" == "available" ]; then
			echo "The snapshot is available"
			exit 0
		fi
		sleep 1s
		((count++))
	done
	echo "ERROR: The snapshot has not become available"
	exit 1

aws-cognito-get-userpool-id: ### Get Cognito userpool ID - mandatory: NAME=[user pool name]; optional: AWS_REGION=[AWS region]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) cognito-idp list-user-pools \
			--region $(AWS_REGION) \
			--max-results 60 \
			--output text \
	" | grep $(NAME) | awk '{ print $$3 }'

aws-cognito-get-client-id: ### Get Cognito client ID - mandatory: NAME=[user pool name]; optional: AWS_REGION=[AWS region]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) cognito-idp list-user-pool-clients \
			--user-pool-id $$(make -s aws-cognito-get-userpool-id NAME=$(NAME)) \
			--region $(AWS_REGION) \
			--query 'UserPoolClients[].ClientId' \
			--output text \
	"

aws-cognito-get-client-secret: ### Get Cognito client secret - mandatory: NAME=[user pool name]; optional: AWS_REGION=[AWS region]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) cognito-idp describe-user-pool-client \
			--user-pool-id $$(make -s aws-cognito-get-userpool-id NAME=$(NAME)) \
			--client-id $$(make -s aws-cognito-get-client-id NAME=$(NAME)) \
			--region $(AWS_REGION) \
			--query 'UserPoolClient.ClientSecret' \
			--output text \
	"

aws-ecr-get-login-password: ### Get the ECR user login password
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) ecr get-login-password --region $(AWS_REGION) \
	"

aws-ses-verify-email-identity: ### Verify SES email address - mandatory: NAME
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) ses verify-email-identity \
			--email-address $(NAME) \
			--region $(AWS_SES_REGION) \
	"

# ==============================================================================

# make aws-iam-policy-create NAME=dan-policy DESCRIPTION=test FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-policy-template.json BUCKET=uec-tools-make-devops-jenkins-workspace
# make aws-iam-role-create NAME=dan-role DESCRIPTION=test FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-role.json
# make aws-iam-role-attach-policy ROLE_NAME=dan-role POLICY_NAME=dan-policy
# aws sts assume-role --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/dan-role --role-session-name dan-test
# make aws-elasticsearch-create-snapshot DOMAIN=sf1-nonprod BUCKET=uec-tools-make-devops-jenkins-workspace IAM_ROLE=dan-role

aws-elasticsearch-create-snapshot: ### Create an Elasticsearch snapshot - mandatory: DOMAIN=[Elasticsearch domain name],SNAPSHOT_NAME
	endpoint=$$(make _aws-elasticsearch-get-endpoint DOMAIN=$(DOMAIN))
	make _aws-elasticsearch-register-snapshot-repository ENDPOINT="$$endpoint"
	#curl -XPUT "https://$$endpoint/_snapshot/snapshot-repository-$(DOMAIN)/$(SNAPSHOT_NAME)"

_aws-elasticsearch-get-endpoint: ### Get Elasticsearch endpoint - mandatory: DOMAIN=[Elasticsearch domain name]
	make -s docker-run-tools ARGS="$$(echo $(AWSCLI) | grep awslocal > /dev/null 2>&1 && echo '--env LOCALSTACK_HOST=$(LOCALSTACK_HOST)' ||:)" CMD=" \
		$(AWSCLI) es describe-elasticsearch-domain \
			--domain-name $(DOMAIN) \
			--region $(AWS_REGION) \
			--query 'DomainStatus.Endpoints.vpc' \
			--output text \
	"

_aws-elasticsearch-register-snapshot-repository: ### Register Elasticsearch snapshot repository - mandatory: ENDPOINT,BUCKET,IAM_ROLE
	json='{"type":"s3","settings":{"bucket":"$(BUCKET)","region":"$(AWS_REGION)","role_arn":"arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(IAM_ROLE)"}}'
	curl -X PUT https://$(ENDPOINT)/_snapshot/dan-role?verify=false -d '{"type":"s3","settings":{"bucket":"$(BUCKET)","region":"$(AWS_REGION)","role_arn":"arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(IAM_ROLE)"}}'
	# make -s docker-run-tools \
	# 	DIR=build/docker/elastic-search-backup/assets/scripts \
	# 	SH=y CMD=" \
	# 		pip install requests-aws4auth && \
	# 		python register-es-repo.py \
	# 			$(ES_ENDPOINT) \
	# 			$(AWS_ACCOUNT_ID) \
	# 			snapshot-repo-$(PROFILE) \
	# 			$(TF_VAR_es_snapshot_bucket) \
	# 			$(TF_VAR_es_snapshot_role) \
	# 	"

# ==============================================================================

.SILENT: \
	_aws-elasticsearch-get-endpoint \
	aws-account-check-id \
	aws-account-get-id \
	aws-assume-role-export-variables \
	aws-cognito-get-client-id \
	aws-cognito-get-client-secret \
	aws-cognito-get-userpool-id \
	aws-ecr-get-login-password \
	aws-iam-policy-exists \
	aws-iam-role-exists \
	aws-rds-describe-instance \
	aws-rds-get-snapshot-status \
	aws-s3-exists \
	aws-secret-create \
	aws-secret-exists \
	aws-secret-get \
	aws-secret-get-and-format \
	aws-secret-put
