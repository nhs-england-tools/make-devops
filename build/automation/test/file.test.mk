TEST_FILE := $(TMP_DIR)/file-remove-multiline-content.txt
TEST_FILE_CONTENT_BEFORE := this\nis\na\nmultiline\nfile
TEST_FILE_CONTENT_AFTER := file
TEST_FILE_CONTENT_TO_REMOVE := this(.)*multiline\n

test-file: \
	test-file-setup \
	test-file-remove-multiline-content \
	test-file-teardown

test-file-setup:
	echo -e "$(TEST_FILE_CONTENT_BEFORE)" > $(TEST_FILE)

test-file-teardown:
	rm -f $(TEST_FILE)

# ==============================================================================

test-file-remove-multiline-content:
	# act
	make file-remove-content \
		FILE=$(TEST_FILE) \
		CONTENT="$(TEST_FILE_CONTENT_TO_REMOVE)"
	# assert
	mk_test $(@) $(TEST_FILE_CONTENT_AFTER) = $$(cat $(TEST_FILE))
