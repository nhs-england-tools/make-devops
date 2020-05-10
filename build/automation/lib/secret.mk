secret-fetch-and-export-variables: ### Get secret and print variable exports - mandatory: NAME=[secret name]; returns: [variables export]
	secret=$$(make aws-secret-get NAME=$(NAME))
	make _secret-export-variables-from-json JSON="$$secret"

secret-fetch: ### Get secret - mandatory: NAME=[secret name]
	make aws-secret-get NAME=$(NAME)

secret-create: ### Set secret - mandatory: NAME=[secret name], VARS=[comma-separated environment variable names]
	file=$(TMP_DIR)/$(PROJECT_NAME)-$(@)-$(BUILD_HASH)-$(BUILD_ID).json
	json=
	for key in $$(echo "$(VARS)" | sed 's/,/\n/g'); do
		value=$$(echo $$(eval echo "\$$$$key"))
		json+="\"$${key}\":\"$${value}\","
	done
	trap "rm -f $$file" EXIT
	echo "{$${json%?}}" > $(TMP_DIR)/$(PROJECT_NAME)-$(@)-$(BUILD_HASH)-$(BUILD_ID).json
	make aws-secret-create NAME=$(NAME) VALUE=file://$$file

secret-random: ### Generate random secret string - optional: LENGTH=[integer]
	str=
	if [ "$$OS" == "unix" ]; then
		str=$$(env LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c $(or $(LENGTH), 32))
	else
		str=</dev/urandom LC_ALL=C tr -dc A-Za-z0-9 | (head -c $$ > /dev/null 2>&1 || head -c $(or $(LENGTH), 32))
	fi
	echo "$$str"

# ==============================================================================

_secret-export-variables-from-json: ### Convert JSON to environment variables - mandatory: JSON='{"key":"value"}'|JSON="$$(echo '$(JSON)')"; returns: [variables export]
	for str in $$(echo '$(JSON)' | make -s docker-run-tools CMD="jq -rf $(JQ_DIR_REL)/json-to-env-vars.jq"); do
		key=$$(cut -d "=" -f1 <<<"$$str")
		value=$$(cut -d "=" -f2- <<<"$$str")
		echo "export $${key}=$${value}"
	done
	make terraform-export-variables-from-json JSON="$$(echo '$(JSON)')"

# ==============================================================================

.SILENT: \
	_secret-export-variables-from-json \
	secret-create \
	secret-fetch \
	secret-fetch-and-export-variables \
	secret-random
