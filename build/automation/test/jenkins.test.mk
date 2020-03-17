test-jenkins: \
	test-jenkins-setup \
	test-jenkins-upload-workspace \
	test-jenkins-teardown

test-jenkins-setup:
	make docker-config
	make docker-compose-start YML=$(TEST_DIR)/docker-compose.localstack.yml

test-jenkins-teardown:
	make docker-compose-stop YML=$(TEST_DIR)/docker-compose.localstack.yml
	rm -rf \
		$(TMP_DIR)/localstack \
		$(TMP_DIR)/workspace-*.tar.gz.download

# ==============================================================================

test-jenkins-upload-workspace:
	# act
	make jenkins-upload-workspace
	# assert
	make aws-s3-download \
		URI=$(JENKINS_WORKSPACE_BUCKET)/$(BUILD_BRANCH)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz \
		FILE=$(TMP_DIR_REL)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download
	mk_test $(@) -f $(TMP_DIR)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download
