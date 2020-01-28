test-techradar: \
	test-techradar-setup \
	test-techradar-image-get-hash \
	test-techradar-image-get-created \
	test-techradar-image-get-size \
	test-techradar-image-get-base \
	test-techradar-image-detect-tech \
	test-techradar-teardown

test-techradar-setup:
	make docker-config

test-techradar-teardown:

# ==============================================================================

test-techradar-image-get-hash:
	mk_test_skip $(@) ||:

test-techradar-image-get-created:
	mk_test_skip $(@) ||:

test-techradar-image-get-size:
	mk_test_skip $(@) ||:

test-techradar-image-get-base:
	mk_test_skip $(@) ||:

test-techradar-image-detect-tech:
	mk_test_skip $(@) ||:
