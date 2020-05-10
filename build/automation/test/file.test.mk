TEST_FILE := $(TMP_DIR)/test-file.txt

test-file:
	make test-file-setup
	tests=( \
		test-file-remove-multiline-content \
		test-file-replace-variables \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-file-teardown

test-file-setup:
	:

test-file-teardown:
	:

# ==============================================================================

test-file-remove-multiline-content:
	# arrange
	echo -e "this\nis\na\nmultiline\nfile" > $(TEST_FILE)
	# act
	make file-remove-content \
		FILE=$(TEST_FILE) \
		CONTENT="this(.)*multiline\n"
	# assert
	mk_test "file = $$(cat $(TEST_FILE))"
	# clean up
	rm -f $(TEST_FILE)

test-file-replace-variables:
	# arrange
	echo VARIABLE_TO_REPLACE > $(TEST_FILE)
	# act
	export VARIABLE=this_is_a_test
	make file-replace-variables FILE=$(TEST_FILE)
	# assert
	mk_test "this_is_a_test = $$(cat $(TEST_FILE))"
	# clean up
	rm -f $(TEST_FILE)
