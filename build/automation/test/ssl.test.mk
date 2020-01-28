TEST_CERT := custom-domain.com

test-ssl: \
	test-ssl-generate-certificate-single-domain \
	test-ssl-generate-certificate-multiple-domains \
	test-ssl-trust-certificate \
	test-ssl-teardown

test-ssl-teardown:
	mk_test_proceed_if_macos && \
		sudo security find-certificate -c $(TEST_CERT) -a -Z | \
		sudo awk '/SHA-1/{system("security delete-certificate -Z "$$NF)}'
	rm -rf $(TMP_DIR)/*.{crt,key,p12,pem}

# ==============================================================================

test-ssl-generate-certificate-single-domain:
	# act
	make ssl-generate-certificate \
		DIR=$(TMP_DIR) \
		NAME=$(TEST_CERT)
	# assert
	mk_test $(@) -f $(TMP_DIR)/$(TEST_CERT).pem

test-ssl-generate-certificate-multiple-domains:
	# act
	make ssl-generate-certificate \
		DIR=$(TMP_DIR) \
		NAME=multi-$(TEST_CERT) \
		DOMAINS=multi-$(TEST_CERT),DNS:*.multi-$(TEST_CERT),DNS:platform.com,DNS:*.platform.com
	# assert
	mk_test $(@) -f $(TMP_DIR)/multi-$(TEST_CERT).pem

test-ssl-trust-certificate:
	mk_test_skip_if_not_macos $(@) && exit ||:
	# arrange
	make ssl-generate-certificate \
		DIR=$(TMP_DIR) \
		NAME=$(TEST_CERT) \
		DOMAINS=$(TEST_CERT),DNS:*.$(TEST_CERT),DNS:other-domain.com,DNS:*.other-domain.com
	# act
	make ssl-trust-certificate \
		FILE=$(TMP_DIR)/$(TEST_CERT).pem
	# assert
	mk_test $(@) 0 -lt "$$(sudo security find-certificate -a -c $(TEST_CERT) | grep -Eo 'alis(.*)$(TEST_CERT)' | wc -l)"
