test-jenkins:
	make test-jenkins-setup
	tests=( \
		test-jenkins-create-pipline-from-template \
		test-jenkins-upload-workspace-archived \
		test-jenkins-upload-workspace-exploded \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-jenkins-teardown

test-jenkins-setup:
	make localstack-start
	# Prerequisites
	make docker-build NAME=tools FROM_CACHE=true

test-jenkins-teardown:
	make localstack-stop
	rm -rf \
		$(TMP_DIR)/localstack \
		$(TMP_DIR)/workspace-*.download

# ==============================================================================

test-jenkins-create-pipline-from-template:
	mk_test_skip

test-jenkins-upload-workspace-archived:
	# act
	make jenkins-upload-workspace ARCHIVE=true
	# assert
	make aws-s3-download \
		URI=$(JENKINS_WORKSPACE_BUCKET_URI)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M%S)-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz \
		FILE=$(TMP_DIR_REL)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M%S)-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download
	mk_test "-f $(TMP_DIR)/workspace-$(PROJECT_NAME_SHORT)-$$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M%S)-$$(printf "%04d\n" $(BUILD_ID))-$(BUILD_HASH).tar.gz.download"

test-jenkins-upload-workspace-exploded:
	# act
	make jenkins-upload-workspace
	# assert
	date=$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")
	id=$$(printf "%04d\n" $(BUILD_ID))
	make aws-s3-download \
		URI=$(JENKINS_WORKSPACE_BUCKET_URI)/$${date}-$${id}-$(BUILD_HASH)/README.md \
		FILE=$(TMP_DIR_REL)/workspace-README.md.download
	mk_test "-f $(TMP_DIR)/workspace-README.md.download"
