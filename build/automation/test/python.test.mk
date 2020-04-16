test-python: \
	test-python-virtualenv \
	test-python-virtualenv-clean

# ==============================================================================

test-python-virtualenv:
	mk_test_skip_if_not_macos $(@) ||:
	# act
	make python-virtualenv
	# assert
	mk_test $(@) "$(PYTHON_VERSION)" = "$$(python --version | awk '{ print $$2 }')"

test-python-virtualenv-clean:
	mk_test_skip_if_not_macos $(@) ||:
	# act
	make python-virtualenv-clean
	# assert
	mk_test $(@) "system" = "$$(pyenv version | grep -o ^system)"
