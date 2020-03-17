jenkins-upload-workspace: ### Upload the project workspace as a file archive to a storage
	eval "$$(make aws-assume-role-export-variables)"
	make aws-session-fail-if-invalid
	date=$$(date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")
	id=$$(printf "%04d\n" $(BUILD_ID))
	file=workspace-$(PROJECT_NAME_SHORT)-$${date}-$${id}-$(BUILD_HASH).tar.gz
	tar --exclude-vcs --exclude='$(TMP_DIR_REL)' -zcvf $(TMP_DIR)/$$file .
	make _jenkins-create-workspace-storage
	make aws-s3-upload \
		FILE=$(TMP_DIR_REL)/$$file \
		URI=$(JENKINS_WORKSPACE_BUCKET)/$(BUILD_BRANCH)/$$file
	rm -f $(TMP_DIR)/workspace-$(PROJECT_NAME_SHORT)-*
	echo "Jenkins workspace URL is https://s3.console.aws.amazon.com/s3/object/$(JENKINS_WORKSPACE_BUCKET)/$(BUILD_BRANCH)/$$file"

_jenkins-create-workspace-storage:
	if [ false == $$(make aws-s3-exists NAME=$(JENKINS_WORKSPACE_BUCKET)) ]; then
		make aws-s3-create NAME=$(JENKINS_WORKSPACE_BUCKET)
	fi
