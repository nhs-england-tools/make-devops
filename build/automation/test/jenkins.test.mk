test-jenkins: \
	test-jenkins-upload-workspace

# ==============================================================================

test-jenkins-upload-workspace:
	mk_test_skip $(@) ||:
