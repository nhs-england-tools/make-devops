test-project:
	make test-project-setup
	tests=( \
		test-project-document-infrastructure \
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

test-project-document-infrastructure:
	# act
	make project-document-infrastructure \
		FIN=$(LIB_DIR_REL)/project/template/infrastructure/diagram.py \
		FOUT=$(TMP_DIR_REL)/diagram
	# assert
	mk_test "-f $(TMP_DIR_REL)/diagram.png"
	# clean up
	rm -f $(TMP_DIR_REL)/diagram.png
