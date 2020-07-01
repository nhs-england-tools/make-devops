test-java:
	make test-java-setup
	tests=( \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-java-teardown

test-java-setup:
	:

test-java-teardown:
	:
