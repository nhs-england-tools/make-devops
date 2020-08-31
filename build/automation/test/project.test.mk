test-project:
	make test-project-setup
	tests=( \
		test-project-config \
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

test-project-config:
	# arrange
	rm -f $(PROJECT_CONFIG_TIMESTAMP_FILE)
	# act
	export BUILD_ID=0
	export PROJECT_CONFIG_TARGET=_test-project-config
	export PROJECT_CONFIG_TIMESTAMP=$(BUILD_TIMESTAMP)
	export PROJECT_CONFIG_FORCE=yes
	output=$$(make project-config | grep "running _test-project-config" | wc -l)
	# assert
	mk_test "target" "0 -lt $$output"
	mk_test "timestamp file" "-f $(PROJECT_CONFIG_TIMESTAMP_FILE)"
	mk_test_complete

test-project-document-infrastructure:
	# act
	make project-document-infrastructure \
		FIN=$(LIB_DIR_REL)/project/template/infrastructure/diagram.py \
		FOUT=$(TMP_DIR_REL)/diagram
	# assert
	mk_test "-f $(TMP_DIR_REL)/diagram.png"
	# clean up
	rm -f $(TMP_DIR_REL)/diagram.png

# ==============================================================================

_test-project-config:
	echo "running _test-project-config"
