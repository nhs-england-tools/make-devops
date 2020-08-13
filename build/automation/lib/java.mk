JAVA_VERSION = 14

java-virtualenv: ### Setup Java virtual environment - optional: JAVA_VERSION
	brew update
	brew cask install adoptopenjdk$(JAVA_VERSION)
	jenv add $$(/usr/libexec/java_home -v$(JAVA_VERSION))
	jenv local $(JAVA_VERSION).0
	sed -i 's;    "java.home":.*;    "java.home": "$(HOME)/.jenv/versions/$(JAVA_VERSION).0",;g' $(PROJECT_DIR)/$(PROJECT_NAME).code-workspace

java-virtualenv-clean: ### Clean up Java virtual environment
	rm -f .java-version

java-clean: ### Clean up Java project files - mandatory: DIR=[Java project directory]
	[ -z "$(DIR)" ] && (echo "ERROR: Please, specify the DIR"; exit 1)
	find $(DIR) \( \
		-name ".settings" -o \
		-name "bin" -o \
		-name "build" -o \
		-name "target" -o \
		-name ".classpath" -o \
		-name ".factorypath" -o \
		-name ".project" -o \
		-name "*.iml" \
	\) -print | xargs rm -rfv
