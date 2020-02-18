TEST_AWS_SECRET_MANAGER_JSON := $(TMP_DIR)/secret.json
TEST_AWS_BUCKET_FILE_NAME := aws-bucket-file
TEST_AWS_BUCKET_FILE_PATH := $(shell echo $(abspath $(TMP_DIR)/$(TEST_AWS_BUCKET_FILE_NAME)) | sed "s;$(PROJECT_DIR);;g")

test-aws: \
	test-aws-setup \
	test-aws-session-fail-if-invalid \
	test-aws-session-fail-if-invalid-error \
	test-aws-assume-role-export-variables \
	test-aws-secret-create-value \
	test-aws-secret-create-object \
	test-aws-secret-put-get-value \
	test-aws-secret-put-get-object \
	test-aws-secret-put-get-and-format \
	test-aws-secret-exists-false \
	test-aws-secret-exists-true \
	test-aws-s3-exists \
	test-aws-s3-create \
	test-aws-s3-upload-download \
	test-aws-ecr-get-login-password \
	test-aws-teardown

test-aws-setup:
	make docker-config
	make docker-compose-start YML=$(TEST_DIR)/docker-compose.localstack.yml
	make docker-image NAME=tools

test-aws-teardown:
	rm -f $(TEST_AWS_SECRET_MANAGER_JSON)
	rm -f $(TEST_AWS_BUCKET_FILE_PATH)*
	make docker-compose-stop YML=$(TEST_DIR)/docker-compose.localstack.yml
	rm -rf $(TMP_DIR)/localstack

# ==============================================================================

test-aws-session-fail-if-invalid:
	# arrange
	export AWS_ACCESS_KEY_ID=gibberish
	export AWS_SECRET_ACCESS_KEY=gibberish
	export AWS_SESSION_TOKEN=gibberish
	# act
	make aws-session-fail-if-invalid && ret_code=0 || ret_code=1
	# assert
	mk_test $(@) 0 = $$ret_code

test-aws-session-fail-if-invalid-error:
	# arrange
	export AWS_ACCESS_KEY_ID=
	export AWS_SECRET_ACCESS_KEY=
	export AWS_SESSION_TOKEN=
	# act
	make aws-session-fail-if-invalid && ret_code=0 || ret_code=1
	# assert
	mk_test $(@) 1 = $$ret_code

test-aws-assume-role-export-variables:
	# # act
	# export=$$(make aws-assume-role-export-variables)
	# # assert
	# mk_test $(@) -n "$$export"
	mk_test_skip $(@) ||:

test-aws-secret-create-value:
	# act
	make aws-secret-create NAME=DB_PASSWORD VALUE=p45w0rd
	secret="$$(make aws-secret-get NAME=DB_PASSWORD)"
	# assert
	mk_test $(@) "p45w0rd" = "$$secret"

test-aws-secret-create-object:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-create NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret=$$(make aws-secret-get NAME=service/deployment-$(@))
	# assert
	mk_test $(@) '{"DB_USERNAME":"admin","DB_PASSWORD":"secret"}' = $$secret

test-aws-secret-put-get-value:
	# act
	make aws-secret-put NAME=DB_PASSWORD VALUE=p45w0rd
	secret="$$(make aws-secret-get NAME=DB_PASSWORD)"
	# assert
	mk_test $(@) "p45w0rd" = "$$secret"

test-aws-secret-put-get-object:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-put NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret=$$(make aws-secret-get NAME=service/deployment-$(@))
	# assert
	mk_test $(@) '{"DB_USERNAME":"admin","DB_PASSWORD":"secret"}' = $$secret

test-aws-secret-put-get-and-format:
	# arrange
	make TEST_AWS_SECRET_MANAGER_JSON
	# act
	make aws-secret-put NAME=service/deployment-$(@) VALUE=file://$(TEST_AWS_SECRET_MANAGER_JSON)
	secret="$$(make aws-secret-get-and-format NAME=service/deployment-$(@))"
	# assert
	mk_test $(@) 4 -eq $$(echo "$$secret" | wc -l)

test-aws-secret-exists-false:
	# act
	reponse="$$(make aws-secret-exists NAME=service/deployment-$(@))"
	# assert
	mk_test $(@) "false" = "$$reponse"

test-aws-secret-exists-true:
	# arrange
	make aws-secret-create NAME=service/deployment-$(@) VALUE=value
	# act
	reponse="$$(make aws-secret-exists NAME=service/deployment-$(@))"
	# assert
	mk_test $(@) "true" = "$$reponse"

test-aws-s3-exists:
	# act
	output=$$(make aws-s3-exists NAME=$(@)-bucket)
	# assert
	mk_test $(@) "false" = "$$output"

test-aws-s3-create:
	# act
	make aws-s3-create NAME=$(@)-bucket
	# assert
	output=$$(make aws-s3-exists NAME=$(@)-bucket)
	mk_test $(@) "true" = "$$output"

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
	mk_test $(@) "$$hash1" = "$$hash2"

test-aws-ecr-get-login-password:
	mk_test_skip $(@) ||:

# ==============================================================================

TEST_AWS_SECRET_MANAGER_JSON:
	echo '{"DB_USERNAME":"admin","DB_PASSWORD":"secret"}' > $(TEST_AWS_SECRET_MANAGER_JSON)
