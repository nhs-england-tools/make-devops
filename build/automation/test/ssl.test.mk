TEST_CERT := custom-domain.com

test-ssl: \
	test-ssl-generate-certificate-single-domain \
	test-ssl-generate-certificate-multiple-domains \
	test-ssl-generate-certificate-project \
	test-ssl-trust-certificate \
	test-ssl-teardown

test-ssl-teardown:
	rm -rf $(TMP_DIR)/*.{crt,key,p12,pem}
	if [ $(PROJECT_NAME) == $(DEVOPS_PROJECT_NAME) ]; then
		mk_test_proceed_if_macos && (
			sudo security find-certificate -c $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT) -a -Z | \
			sudo awk '/SHA-1/{system("security delete-certificate -Z "$$NF)}' && \
			sudo make file-remove-content \
				FILE=/etc/hosts \
				CONTENT="\n# BEGIN: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)(.)*# END: $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)\n" \
		)
		rm -rf $(CERTIFICATE_DIR)/certificate.{crt,key,p12,pem}
	fi

# ==============================================================================

test-ssl-generate-certificate-single-domain:
	# act
	make ssl-generate-certificate \
		DIR=$(TMP_DIR) \
		NAME=$(TEST_CERT) \
		DOMAINS=single-$(TEST_CERT)
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

test-ssl-generate-certificate-project:
	# act
	make ssl-generate-certificate-project DOMAINS=platform.com,*.platform.com
	# assert
	mk_test $(@) -f $(CERTIFICATE_DIR)/certificate.pem

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
	mk_test "$(@) keychain" 0 -lt "$$(sudo security find-certificate -a -c $(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT) | grep -Eo 'alis(.*)$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)' | wc -l)"
	mk_test "$(@) hosts file" 3 -eq "$$(cat /etc/hosts | grep -E '$(PROJECT_NAME_SHORT).local|$(PROJECT_NAME).local|$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local' | wc -l)"
