test-jenkins: \
	test-jenkins-setup \
	test-jenkins-upload-workspace-archived \
	test-jenkins-upload-workspace-exploded \
	test-jenkins-teardown

test-jenkins-setup:
	make docker-config
	make docker-compose-start YML=$(TEST_DIR)/docker-compose.localstack.yml
	sleep 3
	# Prerequisites
	make docker-image NAME=tools

test-jenkins-teardown:
	make docker-compose-stop YML=$(TEST_DIR)/docker-compose.localstack.yml
	rm -rf \
		$(TMP_DIR)/localstack \
		$(TMP_DIR)/workspace-*.download

# ==============================================================================

test-jenkins-upload-workspace-archived:
	# act
	make jenkins-upload-workspace ARCHIVE=true
	# assert
	make aws-s3-download \
		URI=$(JENKINS_WORKSPACE_BUCKET_URI)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz \
		FILE=$(TMP_DIR_REL)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download
	mk_test $(@) -f $(TMP_DIR)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download

test-jenkins-upload-workspace-exploded:
	# act
	make jenkins-upload-workspace
	# assert
	date=$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")
	id=$$(printf "%04d\n" $(BUILD_ID))
	make aws-s3-download \
		URI=$(JENKINS_WORKSPACE_BUCKET_URI)/$${date}-$${id}-$(BUILD_HASH)/README.md \
		FILE=$(TMP_DIR_REL)/workspace-README.md.download
	mk_test $(@) -f $(TMP_DIR)/workspace-README.md.download
