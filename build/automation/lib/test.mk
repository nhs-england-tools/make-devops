TEST_VNC_HOST := localhost
TEST_VNC_PORT := 5900

# ==============================================================================

test-browser: ### Open browser VNC session
	open vnc://$(TEST_VNC_HOST):$(TEST_VNC_PORT)
	echo "The password is: 'secret'"

# ==============================================================================

.SILENT: \
	test-browser
