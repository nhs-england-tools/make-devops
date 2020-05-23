test-project:
	make test-project-setup
	tests=( \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-project-teardown

test-project-setup:
	:

test-project-teardown:
	:
