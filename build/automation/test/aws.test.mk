TEST_AWS_SECRET_MANAGER_JSON = $(TMP_DIR)/secret.json
TEST_AWS_BUCKET_FILE_NAME = aws-bucket-file
TEST_AWS_BUCKET_FILE_PATH = $(shell echo $(abspath $(TMP_DIR)/$(TEST_AWS_BUCKET_FILE_NAME)) | sed "s;$(PROJECT_DIR);;g")

test-aws:
	make test-aws-setup
	tests=( \
		test-aws-session-fail-if-invalid \
		test-aws-session-fail-if-invalid-error \
		test-aws-assume-role-export-variables \
		test-aws-account-check-id \
		test-aws-account-get-id \
		test-aws-secret-create-value \
		test-aws-secret-create-object \
		test-aws-secret-put-get-value \
		test-aws-secret-put-get-object \
		test-aws-secret-put-get-and-format \
		test-aws-secret-exists-false \
		test-aws-secret-exists-true \
		test-aws-iam-policy-create \
		test-aws-iam-policy-exists-true \
		test-aws-iam-policy-exists-false \
		test-aws-iam-role-create \
		test-aws-iam-role-exists-true \
		test-aws-iam-role-exists-false \
		test-aws-iam-role-attach-policy \
		test-aws-s3-exists \
		test-aws-s3-create \
		test-aws-s3-upload-download \
		test-aws-rds-describe-instance \
		test-aws-rds-create-snapshot \
		test-aws-rds-get-snapshot-status \
		test-aws-rds-wait-for-snapshot \
		test-aws-cognito-get-userpool-id \
		test-aws-cognito-get-client-id \
		test-aws-cognito-get-client-secret \
		test-aws-ecr-get-login-password \
		test-aws-ses-verify-email-identity \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-aws-teardown

test-aws-setup:
	make localstack-start
	# Prerequisites
	make docker-pull NAME=tools VERSION=$(DOCKER_LIBRARY_TOOLS_VERSION)

test-aws-teardown:
	make localstack-stop
	rm -rf \
		$(TEST_AWS_BUCKET_FILE_PATH)* \
		$(TEST_AWS_SECRET_MANAGER_JSON)

# ==============================================================================

test-aws-session-fail-if-invalid:
	# arrange
	export AWS_ACCESS_KEY_ID=gibberish
	export AWS_SECRET_ACCESS_KEY=gibberish
	export AWS_SESSION_TOKEN=gibberish
	# act
	make aws-session-fail-if-invalid && ret_code=0 || ret_code=1
	# assert
	mk_test "0 = $$ret_code"

test-aws-session-fail-if-invalid-error:
	# arrange
	export AWS_ACCESS_KEY_ID=
	export AWS_SECRET_ACCESS_KEY=
	export AWS_SESSION_TOKEN=
	# act
	make aws-session-fail-if-invalid && ret_code=0 || ret_code=1
	# assert
	mk_test "1 = $$ret_code"

test-aws-assume-role-export-variables:
	mk_test_skip

test-aws-account-check-id:
	mk_test_skip

test-aws-account-get-id:
	mk_test_skip

test-aws-secret-create-value:
	# act
	make aws-secret-create NAME=DB_PASSWORD VALUE=p45w0rd
	secret="$$(make aws-secret-get NAME=DB_PASSWORD)"
	# assert
	mk_test "p45w0rd = $$secret"

test-aws-secret-create-object:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-create NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret=$$(make aws-secret-get NAME=service/deployment-$(@))
	# assert
	mk_test "{\"DB_USERNAME\":\"admin\",\"DB_PASSWORD\":\"secret\"} = $$secret"

test-aws-secret-put-get-value:
	# act
	make aws-secret-put NAME=DB_PASSWORD VALUE=p45w0rd
	secret="$$(make aws-secret-get NAME=DB_PASSWORD)"
	# assert
	mk_test "p45w0rd = $$secret"

test-aws-secret-put-get-object:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-put NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret=$$(make aws-secret-get NAME=service/deployment-$(@))
	# assert
	mk_test "{\"DB_USERNAME\":\"admin\",\"DB_PASSWORD\":\"secret\"} = $$secret"

test-aws-secret-put-get-and-format:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-put NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret="$$(make aws-secret-get-and-format NAME=service/deployment-$(@))"
	# assert
	mk_test "1 -eq $$(echo $$secret | grep DB_USERNAME | wc -l)"

test-aws-secret-exists-false:
	# act
	output="$$(make aws-secret-exists NAME=service/deployment-$(@))"
	# assert
	mk_test "false = $$output"

test-aws-secret-exists-true:
	# arrange
	make aws-secret-create NAME=service/deployment-$(@) VALUE=value
	# act
	output="$$(make aws-secret-exists NAME=service/deployment-$(@))"
	# assert
	mk_test "true = $$output"

test-aws-iam-policy-create:
	# act
	output=$$(make aws-iam-policy-create \
		NAME=$(@)-test-policy \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-policy-template.json \
		BUCKET_NAME=test-bucket)
	# assert
	mk_test "1 -eq $$(echo \"$$output\" | grep -E '\"PolicyName\".*\"$(@)-test-policy\"' | wc -l)"

test-aws-iam-policy-exists-true:
	# arrange
	make aws-iam-policy-create \
		NAME=$(@)-test-policy \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-policy-template.json
	# act
	output=$$(make aws-iam-policy-exists NAME=$(@)-test-policy)
	# assert
	mk_test "true = $$output"

test-aws-iam-policy-exists-false:
	# act
	output=$$(make aws-iam-policy-exists NAME=$(@)-test-policy-non-existent)
	# assert
	mk_test "false = $$output"

test-aws-iam-role-create:
	# act
	output=$$(make aws-iam-role-create \
		NAME=$(@)-test-role \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-role.json)
	# assert
	mk_test "1 -eq $$(echo \"$$output\" | grep -E '\"RoleName\".*\"$(@)-test-role\"' | wc -l)"

test-aws-iam-role-exists-true:
	# arrange
	make aws-iam-role-create \
		NAME=$(@)-test-role \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-role.json
	# act
	output=$$(make aws-iam-role-exists NAME=$(@)-test-role)
	# assert
	mk_test "true = $$output"

test-aws-iam-role-exists-false:
	# act
	output=$$(make aws-iam-role-exists NAME=$(@)-test-role-non-existent)
	# assert
	mk_test "false = $$output"

test-aws-iam-role-attach-policy:
	# arrange
	make aws-iam-policy-create \
		NAME=$(@)-test-policy \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-policy-template.json
	make aws-iam-role-create \
		NAME=$(@)-test-role \
		DESCRIPTION="This is a test" \
		FILE=build/automation/lib/aws/elasticsearch-s3-snapshot-role.json
	# act
	make aws-iam-role-attach-policy \
		ROLE_NAME=$(@)-test-role \
		POLICY_NAME=$(@)-test-policy
	code=$$?
	# assert
	mk_test "0 -eq $$code"

test-aws-s3-exists:
	# act
	output=$$(make aws-s3-exists NAME=$(@)-bucket)
	# assert
	mk_test "false = $$output"

test-aws-s3-create:
	# act
	make aws-s3-create NAME=$(@)-bucket
	# assert
	output=$$(make aws-s3-exists NAME=$(@)-bucket)
	mk_test "true = $$output"

test-aws-s3-upload-download:
	# arrange
	make aws-s3-create NAME=$(@)-bucket
	echo test > $(TEST_AWS_BUCKET_FILE_PATH).upload
	# act
	make aws-s3-upload \
		FILE=$(TEST_AWS_BUCKET_FILE_PATH).upload \
		URI=$(@)-bucket/$(TEST_AWS_BUCKET_FILE_NAME)
	make aws-s3-download \
		URI=$(@)-bucket/$(TEST_AWS_BUCKET_FILE_NAME) \
		FILE=$(TEST_AWS_BUCKET_FILE_PATH).download
	# assert
	hash1=$$(md5sum $(TEST_AWS_BUCKET_FILE_PATH).upload | awk '{ print $$1 }')
	hash2=$$(md5sum $(TEST_AWS_BUCKET_FILE_PATH).download | awk '{ print $$1 }')
	mk_test "$$hash1 = $$hash2"

test-aws-rds-describe-instance:
	mk_test_skip

test-aws-rds-create-snapshot:
	mk_test_skip

test-aws-rds-get-snapshot-status:
	mk_test_skip

test-aws-rds-wait-for-snapshot:
	mk_test_skip

test-aws-cognito-get-userpool-id:
	mk_test_skip

test-aws-cognito-get-client-id:
	mk_test_skip

test-aws-cognito-get-client-secret:
	mk_test_skip

test-aws-ecr-get-login-password:
	mk_test_skip

test-aws-ses-verify-email-identity:
	mk_test_skip

# ==============================================================================

TEST_AWS_SECRET_MANAGER_JSON:
	echo '{"DB_USERNAME":"admin","DB_PASSWORD":"secret"}' > $(TEST_AWS_SECRET_MANAGER_JSON)
