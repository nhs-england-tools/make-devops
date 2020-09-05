JAVA_VERSION = 14

java-virtualenv: ### Setup Java virtual environment - optional: JAVA_VERSION
	brew update
	brew cask install adoptopenjdk$(JAVA_VERSION)
	jenv add $$(/usr/libexec/java_home -v$(JAVA_VERSION))
	jenv local $(JAVA_VERSION).0
	sed -i 's;    "java.home":.*;    "java.home": "/Library/Java/JavaVirtualMachines/adoptopenjdk-$(JAVA_VERSION).jdk/Contents/Home",;g' project.code-workspace

java-virtualenv-clean: ### Clean up Java virtual environment
	rm -f .java-version

java-clean: ### Clean up Java project files - mandatory: DIR=[Java project directory]; optional: EXCLUDE=[directory, file or pattern]
	[ -z "$(DIR)" ] && (echo "ERROR: Please, specify the DIR"; exit 1)
	[ -n "$(EXCLUDE)" ] && exclude="grep -vE $(EXCLUDE)" || exclude=cat
	find $(DIR) \( \
		-name ".settings" -o \
		-name "bin" -o \
		-name "build" -o \
		-name "target" -o \
		-name ".classpath" -o \
		-name ".factorypath" -o \
		-name ".project" -o \
		-name "*.iml" \
	\) -print | $$exclude | xargs rm -rfv
