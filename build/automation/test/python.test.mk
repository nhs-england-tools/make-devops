test-python:
	make test-python-setup
	tests=( \
		test-python-virtualenv \
		test-python-virtualenv-clean
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-python-teardown

test-python-setup:
	:

test-python-teardown:
	:

# ==============================================================================

test-python-virtualenv:
	mk_test_skip_if_not_macos $(@) && exit ||:
	# act
	make python-virtualenv
	# assert
	mk_test "$(PYTHON_VERSION) = $$(python --version | awk '{ print $$2 }')"

test-python-virtualenv-clean:
	mk_test_skip_if_not_macos $(@) && exit ||:
	# act
	make python-virtualenv-clean
	# assert
	mk_test "system = $$(pyenv version | grep -o ^system)"
