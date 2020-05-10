test-localstack: \
	test-localstack-start-stop

# ==============================================================================

test-localstack-start-stop:
	# act & assert
	make localstack-start && \
		mk_test_pass "$(@) start" || mk_test_fail "$(@) start"
	make localstack-stop && \
		mk_test_pass "$(@) stop" || mk_test_fail "$(@) stop"
