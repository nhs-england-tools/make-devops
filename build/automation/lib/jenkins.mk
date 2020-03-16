jenkins-upload-workspace:
	eval "$$(make aws-assume-role-export-variables)"
	make aws-session-fail-if-invalid
	aws s3 cp $(WORKSPACE) \
		s3://$(JENKINS_WORKSPACE_BUCKET)/$(BUILD_BRANCH)_$(BUILD_NUMBER) \
		--recursive \
		--exclude ".git/*" \
		--quiet
	echo "Jenkins Workspace Bucket URL in Non Prod is: https://s3.console.aws.amazon.com/s3/buckets/$(JENKINS_WORKSPACE_BUCKET)/$(BUILD_BRANCH)_$(BUILD_NUMBER)/"
