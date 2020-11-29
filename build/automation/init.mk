help: help-project-development # Show project specific development workflow targets

help-all: # Show all targets
	tput setaf 190; printf "\nProject specific development workflow targets\n\n"; tput sgr 0
	make help-project-development
	tput setaf 190; printf "\nProject specific supporting and deployment workflow targets\n\n"; tput sgr 0
	make help-project-supporting
	tput setaf 190; printf "\nLibrary targets\n\n"; tput sgr 0
	make help-library

help-project-development: ### Show project specific development workflow targets
	@awk 'BEGIN {FS = ":.*?# "} /^[ a-zA-Z0-9_-]+:.*? # / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

help-project-supporting: ### Show project specific supporting and deployment workflow targets
	@awk 'BEGIN {FS = ":.*?## "} /^[ a-zA-Z0-9_-]+:.*? ## / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

help-library: ### Show library targets
	@awk 'BEGIN {FS = ":.*?### "} /^[ a-zA-Z0-9_-]+:.*? ### / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

devops-print-variables show-configuration: ### Print all the variables
	$(foreach v, $(sort $(.VARIABLES)),
		$(if $(filter-out default automatic, $(origin $v)),
			$(if $(and $(patsubst %_PASSWORD,,$v), $(patsubst %_SECRET,,$v)),
				$(info $v=$($v) ($(value $v)) [$(flavor $v),$(origin $v)]),
				$(info $v=****** (******) [$(flavor $v),$(origin $v)])
			)
		)
	)

devops-get-variable get-variable: ### Get the specified variable - mandatory: NAME=[variable name]
	echo $${$(NAME)}

devops-test-suite: ### Run the DevOps unit test suite - optional: DEBUG=true
	make _devops-test DEBUG=$(DEBUG) TESTS=" \
		test-file \
		test-ssl \
		test-git \
		test-docker \
		test-localstack \
		test-aws \
		test-secret \
		test-terraform \
		test-k8s \
		test-jenkins \
		test-python \
		test-java \
		test-node \
		test-postgres \
		test-techradar \
		test-project \
	"
	find $(TMP_DIR) -mindepth 1 -maxdepth 1 -not -name '.gitignore' -print | xargs rm -rf

devops-test-single: ### Run a DevOps single test - mandatory NAME=[test target name]; optional: DEBUG=true
	make _devops-test DEBUG=$(DEBUG) TESTS="$(NAME)"

_devops-test:
	[ "$(AWS_ACCOUNT_ID_LIVE_PARENT)" == 000000000000 ] && echo "AWS_ACCOUNT_ID_LIVE_PARENT has not been set with a valid AWS account ID (this might be desired for testing or local development)"
	[ "$(AWS_ACCOUNT_ID_MGMT)" == 000000000000 ] && echo "AWS_ACCOUNT_ID_MGMT has not been set with a valid AWS account ID (this might be desired for testing or local development)"
	[ "$(AWS_ACCOUNT_ID_NONPROD)" == 000000000000 ] && echo "AWS_ACCOUNT_ID_NONPROD has not been set with a valid AWS account ID (this might be desired for testing or local development)"
	[ "$(AWS_ACCOUNT_ID_PROD)" == 000000000000 ] && echo "AWS_ACCOUNT_ID_PROD has not been set with a valid AWS account ID (this might be desired for testing or local development)"
	export _DEVOPS_RUN_TEST=true
	if [[ "$(DEBUG)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		exec 3>&1
		exec 5>&1
		config=".SHELLFLAGS=-cex"
	else
		exec 3>/dev/null
		exec 5>&1
		config="-s"
	fi
	source $(TEST_DIR)/test.sh
	make $$config AWS_ACCOUNT_ID=000000000000 \
		$(TESTS) \
	>&3 2>&3

devops-test-cleanup: ### Clean up adter the tests
	docker network rm $(DOCKER_NETWORK) 2> /dev/null ||:
	# TODO: Remove older networks that remained after unsuccessful builds

devops-copy: ### Copy the DevOps automation toolchain scripts to given destination - optional: DIR
	function sync() {
		cd $(PROJECT_DIR)
		mkdir -p \
			$(DIR)/.github \
			$(DIR)/documentation/adr \
			$(DIR)/documentation/diagrams
		# Library files
		rsync -rav \
			--include=build/ \
			--exclude=automation/etc/certificate/certificate.* \
			--exclude=automation/var/project.mk \
			--exclude=Jenkinsfile \
			build/* \
			$(DIR)/build
		cp -fv .github/CODEOWNERS $(DIR)/.github/CODEOWNERS && sed -i "s;@nhsd-exeter/admins;@nhsd-exeter/maintainers;" $(DIR)/.github/CODEOWNERS
		cp -fv LICENSE.md $(DIR)/build/automation/LICENSE.md
		[ -f $(DIR)/build/automation/etc/certificate/*.pem ] && rm -fv $(DIR)/build/automation/etc/certificate/.gitignore
		# Project key files
		[ ! -f $(DIR)/Makefile ] && cp -fv build/automation/lib/project/template/Makefile $(DIR)
		cp -fv build/automation/lib/project/template/.editorconfig $(DIR)
		cp -fv build/automation/lib/project/template/.gitattributes $(DIR)
		cp -fv build/automation/lib/project/template/.gitignore $(DIR)
		cp -fv build/automation/lib/project/template/project.code-workspace $(DIR)
		# Project documentation
		[ ! -f $(DIR)/README.md ] && cp -fv build/automation/lib/project/template/README.md $(DIR)
		[ ! -f $(DIR)/TODO.md ] && cp -fv build/automation/lib/project/template/TODO.md $(DIR)/documentation
		cp -fv build/automation/lib/project/template/CONTRIBUTING.md $(DIR)/documentation
		cp -fv build/automation/lib/project/template/ONBOARDING.md $(DIR)/documentation
		cp -fv build/automation/lib/project/template/documentation/adr/README.md $(DIR)/documentation/adr
		cp -fv build/automation/lib/project/template/documentation/diagrams/DevOps-Pipelines.png $(DIR)/documentation/diagrams
		# ---
		[ -f $(DIR)/CONTRIBUTING.md ] && mv -fv $(DIR)/CONTRIBUTING.md $(DIR)/documentation
		[ -f $(DIR)/TODO.md ] && mv -fv $(DIR)/TODO.md $(DIR)/documentation
		# ---
		make _devops-project-clean DIR=$(DIR)
		# ---
		return 0
	}
	function version() {
		cd $(PROJECT_DIR)
		tag=$$([ -n "$$(git tag --points-at HEAD)" ] && echo $$(git tag --points-at HEAD) || echo v$$(git show -s --format=%cd --date=format:%Y%m%d%H%M%S))
		hash=$$(git rev-parse --short HEAD)
		echo "$${tag:1}-$${hash}" > $(DIR)/build/automation/VERSION
	}
	mkdir -p $(DIR)/build
	sync && version

devops-update devops-synchronise: ### Update/upgrade the DevOps automation toolchain scripts used by this project - optional: LATEST=true
	function download() {
		cd $(PROJECT_DIR)
		rm -rf \
			$(TMP_DIR)/$(DEVOPS_PROJECT_NAME) \
			.git/modules/build \
			.gitmodules
		git submodule add --force \
			https://github.com/$(DEVOPS_PROJECT_ORG)/$(DEVOPS_PROJECT_NAME).git \
			$$(echo $(abspath $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)) | sed "s;$(PROJECT_DIR);;g")
		if [[ ! "$(LATEST)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
			tag=$$(make _devops-synchronise-select-tag-to-install)
			cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
			git checkout $$tag
		fi
	}
	function sync() {
		cd $(PROJECT_DIR)
		mkdir -p \
			$(PARENT_PROJECT_DIR)/.github \
			$(PARENT_PROJECT_DIR)/documentation/adr \
			$(PARENT_PROJECT_DIR)/documentation/diagrams
		# Library files
		rsync -rav \
			--include=build/ \
			--exclude=automation/etc/certificate/certificate.* \
			--exclude=automation/var/project.mk \
			--exclude=Jenkinsfile \
			build/* \
			$(PARENT_PROJECT_DIR)/build
		cp -fv .github/CODEOWNERS $(PARENT_PROJECT_DIR)/.github/CODEOWNERS && sed -i "s;@nhsd-exeter/admins;@nhsd-exeter/maintainers;" $(PARENT_PROJECT_DIR)/.github/CODEOWNERS
		cp -fv LICENSE.md $(PARENT_PROJECT_DIR)/build/automation/LICENSE.md
		[ -f $(PARENT_PROJECT_DIR)/build/automation/etc/certificate/*.pem ] && rm -fv $(PARENT_PROJECT_DIR)/build/automation/etc/certificate/.gitignore
		[ -f $(PARENT_PROJECT_DIR)/docker/docker-compose.yml ] && rm -fv $(PARENT_PROJECT_DIR)/docker/.gitkeep
		# Project key files
		[ ! -f $(PARENT_PROJECT_DIR)/Makefile ] && cp -fv build/automation/lib/project/template/Makefile $(PARENT_PROJECT_DIR)
		cp -fv build/automation/lib/project/template/.editorconfig $(PARENT_PROJECT_DIR)
		cp -fv build/automation/lib/project/template/.gitattributes $(PARENT_PROJECT_DIR)
		cp -fv build/automation/lib/project/template/.gitignore $(PARENT_PROJECT_DIR)
		cp -fv build/automation/lib/project/template/project.code-workspace $(PARENT_PROJECT_DIR)
		# Project documentation
		[ ! -f $(PARENT_PROJECT_DIR)/README.md ] && cp -fv build/automation/lib/project/template/README.md $(PARENT_PROJECT_DIR)
		[ ! -f $(PARENT_PROJECT_DIR)/TODO.md ] && cp -fv build/automation/lib/project/template/TODO.md $(PARENT_PROJECT_DIR)/documentation
		cp -fv build/automation/lib/project/template/CONTRIBUTING.md $(PARENT_PROJECT_DIR)/documentation
		cp -fv build/automation/lib/project/template/ONBOARDING.md $(PARENT_PROJECT_DIR)/documentation
		cp -fv build/automation/lib/project/template/documentation/adr/README.md $(PARENT_PROJECT_DIR)/documentation/adr
		cp -fv build/automation/lib/project/template/documentation/diagrams/DevOps-Pipelines.png $(PARENT_PROJECT_DIR)/documentation/diagrams
		# ---
		[ -f $(PARENT_PROJECT_DIR)/CONTRIBUTING.md ] && mv -fv $(PARENT_PROJECT_DIR)/CONTRIBUTING.md $(PARENT_PROJECT_DIR)/documentation
		[ -f $(PARENT_PROJECT_DIR)/TODO.md ] && mv -fv $(PARENT_PROJECT_DIR)/TODO.md $(PARENT_PROJECT_DIR)/documentation
		# ---
		make _devops-project-clean DIR=$(PARENT_PROJECT_DIR)
		# ---
		return 0
	}
	function version() {
		cd $(PROJECT_DIR)
		make get-variable NAME=DEVOPS_PROJECT_VERSION > $(PARENT_PROJECT_DIR)/build/automation/VERSION
	}
	function cleanup() {
		rm -rf \
			$(PROJECT_DIR) \
			.git/modules/build \
			.gitmodules
		git reset -- .gitmodules
		git reset -- build/automation/tmp/$(DEVOPS_PROJECT_NAME)
	}
	function commit() {
		cd $(PROJECT_DIR)
		version=$$(make get-variable NAME=DEVOPS_PROJECT_VERSION)
		cd $(PARENT_PROJECT_DIR)
		if [ 0 -lt $$(git status -s | wc -l) ]; then
			git add .
			git commit -S -m "Update the DevOps automation toolchain scripts to $$version"
		fi
	}
	if [ -z "$(__DEVOPS_SYNCHRONISE)" ]; then
		branch=$$(git rev-parse --abbrev-ref HEAD)
		[ $$branch != "task/Update_automation_scripts" ] && git checkout -b task/Update_automation_scripts
		download
		cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
		make devops-synchronise \
			PARENT_PROJECT_DIR=$(PROJECT_DIR) \
			PARENT_PROJECT_NAME=$(PROJECT_NAME) \
			__DEVOPS_SYNCHRONISE=true
	else
		if [ 0 -lt $$(git status -s | wc -l) ]; then
			echo "ERROR: Please, commit your changes first"
			exit 1
		fi
		sync && version && cleanup && commit
	fi

_devops-project-clean: ### Clean up the project structure - mandatory: DIR=[project directory]
	# Remove not needed project files
	[ -n "$(DIR)" ] && rm -f $(DIR)/build/docker/.gitkeep
	# Remove empty project directories
	[ -n "$(DIR)" ] && rmdir $(DIR)/build/docker ||:
	# Remove old project files and directories
	rm -rf \
		~/bin/docker-compose-processor \
		~/bin/texas-mfa \
		~/bin/texas-mfa-clear.sh \
		~/bin/toggle-natural-scrolling.sh \
		~/usr/mfa-aliases
	[ -n "$(DIR)" ] && rm -rf \
		$(DIR)/build/automation/bin/markdown.pl \
		$(DIR)/build/automation/etc/githooks/scripts/*.default \
		$(DIR)/build/automation/etc/platform-texas* \
		$(DIR)/build/automation/lib/dev.mk \
		$(DIR)/build/automation/lib/docker/nginx \
		$(DIR)/build/automation/lib/docker/postgres \
		$(DIR)/build/automation/lib/docker/tools \
		$(DIR)/build/automation/lib/fix \
		$(DIR)/build/automation/lib/k8s/template/deployment/stacks/stack/base/template/network-policy \
		$(DIR)/build/automation/lib/k8s/template/deployment/stacks/stack/base/template/STACK_TEMPLATE_TO_REPLACE/network-policy.yaml \
		$(DIR)/build/automation/lib/slack/jenkins-pipeline.json \
		$(DIR)/build/automation/usr/mfa-aliases \
		$(DIR)/build/automation/var/helpers.mk.default \
		$(DIR)/build/automation/var/override.mk.default \
		$(DIR)/build/automation/var/platform-texas/account-*.mk \
		$(DIR)/build/docker/Dockerfile.metadata \
		$(DIR)/documentation/DevOps-Pipelines.png \
		$(DIR)/documentation/DevOps.drawio
	exit 0

_devops-synchronise-select-tag-to-install: ### TODO: This is WIP
	cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
	git tag -l | sort -r | head -n 1
	# data=
	# for tag in $$(git tag -l | sort -r); do
	# 	data="$${data} $$tag $$tag off"
	# done
	# cmd=(dialog --title "Available Releases"  --radiolist "\nSelect tag to install:" 16 32 16)
	# options=($${data})
	# echo "$${options[@]}"
	# choices=$$("$${cmd[@]}" "$${options[@]}" 2>&1 > /dev/tty)
	# for choice in $$choices; do
	# 	echo "$$choice"
	# done

devops-setup-aws-accounts: ### Ask user to input valid AWS account IDs to be used by the DevOps automation toolchain scripts
	file=$(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform.zsh
	if [ -f $$file ]; then
		parent_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_LIVE_PARENT=" | sed "s/export AWS_ACCOUNT_ID_LIVE_PARENT=//")
		mgmt_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_MGMT=" | sed "s/export AWS_ACCOUNT_ID_MGMT=//")
		nonprod_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_NONPROD=" | sed "s/export AWS_ACCOUNT_ID_NONPROD=//")
		prod_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_PROD=" | sed "s/export AWS_ACCOUNT_ID_PROD=//")
		printf "\nPlease, provide valid AWS account IDs or press ENTER to leave it unchanged.\n\n"
		read -p "AWS_ACCOUNT_ID_LIVE_PARENT ($$parent_id) : " new_parent_id
		read -p "AWS_ACCOUNT_ID_MGMT        ($$mgmt_id) : " new_mgmt_id
		read -p "AWS_ACCOUNT_ID_NONPROD     ($$nonprod_id) : " new_nonprod_id
		read -p "AWS_ACCOUNT_ID_PROD        ($$prod_id) : " new_prod_id
		printf "\n"
		if [ -n "$$new_parent_id" ]; then
			make -s file-replace-content \
				FILE=$$file \
				OLD="export AWS_ACCOUNT_ID_LIVE_PARENT=$$parent_id" \
				NEW="export AWS_ACCOUNT_ID_LIVE_PARENT=$$new_parent_id" \
			> /dev/null 2>&1
		fi
		if [ -n "$$new_mgmt_id" ]; then
			make -s file-replace-content \
				FILE=$$file \
				OLD="export AWS_ACCOUNT_ID_MGMT=$$mgmt_id" \
				NEW="export AWS_ACCOUNT_ID_MGMT=$$new_mgmt_id" \
			> /dev/null 2>&1
		fi
		if [ -n "$$new_nonprod_id" ]; then
			make -s file-replace-content \
				FILE=$$file \
				OLD="export AWS_ACCOUNT_ID_NONPROD=$$nonprod_id" \
				NEW="export AWS_ACCOUNT_ID_NONPROD=$$new_nonprod_id" \
			> /dev/null 2>&1
		fi
		if [ -n "$$new_prod_id" ]; then
			make -s file-replace-content \
				FILE=$$file \
				OLD="export AWS_ACCOUNT_ID_PROD=$$prod_id" \
				NEW="export AWS_ACCOUNT_ID_PROD=$$new_prod_id" \
			> /dev/null 2>&1
		fi
		printf "FILE: $$file\n"
		cat $$file
		printf "Please, run \`reload\` to make sure that this change takes effect\n\n"
	else
		printf "\nERROR: Please, before proceeding run \`make macos-setup\`\n\n"
	fi

devops-setup-aws-accounts-for-service: ### Ask user to input valid AWS account IDs to be used by the DevOps automation toolchain scripts for service accounts
	file=$(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-default.zsh
	[ ! -f $$file ] && cp -vf $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform.zsh $$file
	printf "\nWhat's the service name?\n\n"
	read -p "PROJECT_ID : " project_id
	file=$(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-$$project_id.zsh
	(
		echo
		echo "# export: AWS platform variables"
		echo "export AWS_ACCOUNT_ID_TOOLS=000000000000"
		echo "export AWS_ACCOUNT_ID_NONPROD=000000000000"
		echo "export AWS_ACCOUNT_ID_PROD=000000000000"
		echo
	) > $$file
	tools_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_TOOLS=" | sed "s/export AWS_ACCOUNT_ID_TOOLS=//")
	nonprod_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_NONPROD=" | sed "s/export AWS_ACCOUNT_ID_NONPROD=//")
	prod_id=$$(cat $$file | grep "export AWS_ACCOUNT_ID_PROD=" | sed "s/export AWS_ACCOUNT_ID_PROD=//")
	printf "\nPlease, provide valid AWS account IDs or press ENTER to leave it unchanged.\n\n"
	read -p "AWS_ACCOUNT_ID_TOOLS       ($$tools_id) : " new_tools_id
	read -p "AWS_ACCOUNT_ID_NONPROD     ($$nonprod_id) : " new_nonprod_id
	read -p "AWS_ACCOUNT_ID_PROD        ($$prod_id) : " new_prod_id
	printf "\n"
	if [ -n "$$new_tools_id" ]; then
		make -s file-replace-content \
			FILE=$$file \
			OLD="export AWS_ACCOUNT_ID_TOOLS=$$tools_id" \
			NEW="export AWS_ACCOUNT_ID_TOOLS=$$new_tools_id" \
		> /dev/null 2>&1
	fi
	if [ -n "$$new_nonprod_id" ]; then
		make -s file-replace-content \
			FILE=$$file \
			OLD="export AWS_ACCOUNT_ID_NONPROD=$$nonprod_id" \
			NEW="export AWS_ACCOUNT_ID_NONPROD=$$new_nonprod_id" \
		> /dev/null 2>&1
	fi
	if [ -n "$$new_prod_id" ]; then
		make -s file-replace-content \
			FILE=$$file \
			OLD="export AWS_ACCOUNT_ID_PROD=$$prod_id" \
			NEW="export AWS_ACCOUNT_ID_PROD=$$new_prod_id" \
		> /dev/null 2>&1
	fi
	printf "FILE: $$file\n"
	cat $$file
	make -s file-replace-content \
		FILE=$(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/$(DEVOPS_PROJECT_NAME).plugin.zsh \
		OLD="\. .*/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform(.)*\.zsh" \
		NEW="\. $$file" \
	> /dev/null 2>&1
	printf "Please, run \`reload\` to make sure that this change takes effect\n\n"

devops-switch-aws-accounts: ### Switch among the set of AWS accounts to be used by the DevOps automation toolchain scripts
	printf "\n"
	i=1
	for service in $$(ls -1 $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-*.zsh | sed "s;.*/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-;;g" | sed "s;.zsh;;g"); do
		echo $$i $$service
		i=$$((i+1))
	done
	printf "\nPlease, select the service? "
	read -p "" service_id
	i=1
	for service in $$(ls -1 $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-*.zsh | sed "s;.*/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-;;g" | sed "s;.zsh;;g"); do
		if [ $$i == "$$service_id" ]; then
			make -s file-replace-content \
				FILE=$(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/$(DEVOPS_PROJECT_NAME).plugin.zsh \
				OLD="\. .*/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform(.)*\.zsh" \
				NEW="\. $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-$$service.zsh"
			printf "FILE: $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-$$service.zsh\n"
			cat $(DEV_OHMYZSH_DIR)/plugins/$(DEVOPS_PROJECT_NAME)/aws-platform-$$service.zsh
			printf "Please, run \`reload\` to make sure that this change takes effect\n\n"
			break
		fi
		i=$$((i+1))
	done

# TODO: Refactor `devops-setup-aws-accounts`, `devops-setup-aws-accounts-for-service` and `devops-switch-aws-accounts`

# ==============================================================================
# Project configuration

DEVOPS_PROJECT_ORG := nhsd-exeter
DEVOPS_PROJECT_NAME := make-devops
DEVOPS_PROJECT_DIR := $(abspath $(lastword $(MAKEFILE_LIST))/..)
DEVOPS_PROJECT_VERSION := $(or $(shell git tag --points-at HEAD 2> /dev/null | sed "s/v//g" ||:), $(shell echo $$(git show -s --format=%cd --date=format:%Y%m%d%H%M%S 2> /dev/null ||:)-$$(git rev-parse --short HEAD 2> /dev/null ||:)))

BIN_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/bin)
BIN_DIR_REL := $(shell echo $(BIN_DIR) | sed "s;$(PROJECT_DIR);;g")
ETC_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/etc)
ETC_DIR_REL := $(shell echo $(ETC_DIR) | sed "s;$(PROJECT_DIR);;g")
LIB_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/lib)
LIB_DIR_REL := $(shell echo $(LIB_DIR) | sed "s;$(PROJECT_DIR);;g")
TEST_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/test)
TEST_DIR_REL := $(shell echo $(TEST_DIR) | sed "s;$(PROJECT_DIR);;g")
TMP_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/tmp)
TMP_DIR_REL := $(shell echo $(TMP_DIR) | sed "s;$(PROJECT_DIR);;g")
USR_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/usr)
USR_DIR_REL := $(shell echo $(USR_DIR) | sed "s;$(PROJECT_DIR);;g")
VAR_DIR := $(abspath $(DEVOPS_PROJECT_DIR)/var)
VAR_DIR_REL := $(shell echo $(VAR_DIR) | sed "s;$(PROJECT_DIR);;g")

APPLICATION_DIR := $(abspath $(or $(APPLICATION_DIR), $(PROJECT_DIR)/application))
APPLICATION_DIR_REL = $(shell echo $(APPLICATION_DIR) | sed "s;$(PROJECT_DIR);;g")
APPLICATION_TEST_DIR := $(abspath $(or $(APPLICATION_TEST_DIR), $(PROJECT_DIR)/test))
APPLICATION_TEST_DIR_REL = $(shell echo $(APPLICATION_TEST_DIR) | sed "s;$(PROJECT_DIR);;g")
CONFIG_DIR := $(abspath $(or $(CONFIG_DIR), $(PROJECT_DIR)/config))
CONFIG_DIR_REL = $(shell echo $(CONFIG_DIR) | sed "s;$(PROJECT_DIR);;g")
DATA_DIR := $(abspath $(or $(DATA_DIR), $(PROJECT_DIR)/data))
DATA_DIR_REL = $(shell echo $(DATA_DIR) | sed "s;$(PROJECT_DIR);;g")
DEPLOYMENT_DIR := $(abspath $(or $(DEPLOYMENT_DIR), $(PROJECT_DIR)/deployment))
DEPLOYMENT_DIR_REL = $(shell echo $(DEPLOYMENT_DIR) | sed "s;$(PROJECT_DIR);;g")
GITHOOKS_DIR := $(abspath $(ETC_DIR)/githooks)
GITHOOKS_DIR_REL = $(shell echo $(GITHOOKS_DIR) | sed "s;$(PROJECT_DIR);;g")
DOCUMENTATION_DIR := $(abspath $(or $(DOCUMENTATION_DIR), $(PROJECT_DIR)/documentation))
DOCUMENTATION_DIR_REL = $(shell echo $(DOCUMENTATION_DIR) | sed "s;$(PROJECT_DIR);;g")
INFRASTRUCTURE_DIR := $(abspath $(or $(INFRASTRUCTURE_DIR), $(PROJECT_DIR)/infrastructure))
INFRASTRUCTURE_DIR_REL = $(shell echo $(INFRASTRUCTURE_DIR) | sed "s;$(PROJECT_DIR);;g")
JQ_DIR_REL := $(shell echo $(abspath $(LIB_DIR)/jq) | sed "s;$(PROJECT_DIR);;g")

GIT_BRANCH_PATTERN_MAIN := ^(master|main|develop)$$
GIT_BRANCH_PATTERN_PREFIX := ^(task|story|epic|spike|fix|test|release|migration)
GIT_BRANCH_PATTERN_SUFFIX := [A-Za-z]{2,5}-[0-9]{1,5}_[A-Za-z0-9_]{4,32}$$
GIT_BRANCH_PATTERN := $(GIT_BRANCH_PATTERN_MAIN)|$(GIT_BRANCH_PATTERN_PREFIX)/$(GIT_BRANCH_PATTERN_SUFFIX)

BUILD_ID := $(or $(or $(or $(BUILD_ID), $(CIRCLE_BUILD_NUM)), $(CODEBUILD_BUILD_NUMBER)), 0)
BUILD_DATE := $(or $(BUILD_DATE), $(shell date -u +"%Y-%m-%dT%H:%M:%S%z"))
BUILD_TIMESTAMP := $(shell date --date=$(BUILD_DATE) -u +"%Y%m%d%H%M%S")
BUILD_REPO := $(or $(shell git config --get remote.origin.url 2> /dev/null ||:), unknown)
BUILD_BRANCH := $(if $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null | grep -E ^HEAD$ ||:),$(or $(shell git name-rev --name-only HEAD 2> /dev/null | sed "s;remotes/origin/;;g" ||:), unknown),$(or $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null | sed "s;remotes/origin/;;g" ||:), unknown))
BUILD_COMMIT_HASH := $(or $(shell git rev-parse --short HEAD 2> /dev/null ||:), unknown)
BUILD_COMMIT_DATE := $(or $(shell TZ=UTC git show -s --format=%cd --date=format-local:%Y-%m-%dT%H:%M:%S%z HEAD 2> /dev/null ||:), unknown)
BUILD_COMMIT_AUTHOR_NAME := $(shell git show -s --format='%an' HEAD 2> /dev/null ||:)
BUILD_COMMIT_AUTHOR_EMAIL := $(shell git show -s --format='%ae' HEAD 2> /dev/null ||:)
BUILD_COMMIT_MESSAGE := $(shell git log -1 --pretty=%B HEAD 2> /dev/null ||:)
USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)
TTY_ENABLE := $(or $(TTY_ENABLE), $(shell [ $(BUILD_ID) -eq 0 ] && echo true || echo false))
_TTY := $$([ -t 0 ] && [ $(TTY_ENABLE) = true ] && echo "--tty")
GOSS_PATH := $(BIN_DIR)/goss-linux-amd64
SETUP_COMPLETE_FLAG_FILE := $(TMP_DIR)/.make-devops-setup-complete

PROFILE := $(or $(PROFILE), local)
ENVIRONMENT := $(or $(ENVIRONMENT), $(shell ([ $(PROFILE) = local ] && echo local) || ( echo $(BUILD_BRANCH) | grep -Eoq '$(GIT_BRANCH_PATTERN_SUFFIX)' && (echo $(BUILD_BRANCH) | grep -Eo '[A-Za-z]{2,5}-[0-9]{1,5}' | tr '[:upper:]' '[:lower:]') || ([ $(BUILD_BRANCH) = master ] && echo $(PROFILE)))))

# ==============================================================================
# `make` configuration

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.NOTPARALLEL:
.ONESHELL:
.PHONY: *
MAKEFLAGS := --no-print-director
PATH := /usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/make/libexec/gnubin:$(BIN_DIR):$(PATH)
SHELL := /bin/bash
ifeq (true, $(shell [[ "$(DEBUG)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]] && echo true))
	.SHELLFLAGS := -cex
else
	.SHELLFLAGS := -ce
endif

# ==============================================================================
# Include additional libraries and customisations

include $(LIB_DIR)/*.mk
ifneq ("$(wildcard $(VAR_DIR)/*.mk)", "")
	include $(VAR_DIR)/*.mk
else
	# Load only if the service project file doesn't exist
	-include $(VAR_DIR)/project.mk.default
endif
ifneq ("$(wildcard $(VAR_DIR)/profile/$(PROFILE).mk)", "")
	include $(VAR_DIR)/profile/$(PROFILE).mk
else
	# Load only if the service profile file doesn't exist
	-include $(VAR_DIR)/profile/$(PROFILE).mk.default
endif
ifeq ("$(_DEVOPS_RUN_TEST)", "true")
	include $(TEST_DIR)/*.mk
	AWSCLI := awslocal
else
	AWSCLI := aws
endif

# ==============================================================================
# Check if all the required variables are set

ifeq (true, $(shell [ "local" == "$(PROFILE)" ] && echo true))
AWS_ACCOUNT_ID_LIVE_PARENT := $(or $(AWS_ACCOUNT_ID_LIVE_PARENT), 000000000000)
AWS_ACCOUNT_ID_MGMT := $(or $(AWS_ACCOUNT_ID_MGMT), 000000000000)
AWS_ACCOUNT_ID_TOOLS := $(or $(AWS_ACCOUNT_ID_TOOLS), 000000000000)
AWS_ACCOUNT_ID_NONPROD := $(or $(AWS_ACCOUNT_ID_NONPROD), 000000000000)
AWS_ACCOUNT_ID_PROD := $(or $(AWS_ACCOUNT_ID_PROD), 000000000000)
endif

ifndef PROJECT_DIR
$(error PROJECT_DIR is not set in the main Makefile)
endif
ifndef PROJECT_GROUP
$(error PROJECT_GROUP is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_GROUP_SHORT
$(error PROJECT_GROUP_SHORT is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_NAME
$(error PROJECT_NAME is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_NAME_SHORT
$(error PROJECT_NAME_SHORT is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_DISPLAY_NAME
$(error PROJECT_DISPLAY_NAME is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_ID
$(error PROJECT_ID is not set in build/automation/var/project.mk)
endif
ifndef PROGRAMME
$(error PROGRAMME is not set in build/automation/var/project.mk)
endif

ifndef SERVICE_TAG
$(error SERVICE_TAG is not set in build/automation/var/project.mk)
endif
ifndef PROJECT_TAG
$(error PROJECT_TAG is not set in build/automation/var/project.mk)
endif
ifndef ROLE_PREFIX
$(error ROLE_PREFIX is not set in build/automation/var/project.mk)
endif

ifeq (true, $(shell [ -z "$(AWS_ACCOUNT_ID_LIVE_PARENT)" ] && [ -z "$(AWS_ACCOUNT_ID_TOOLS)" ] && echo true))
$(info AWS_ACCOUNT_ID_LIVE_PARENT is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config, run `make devops-setup-aws-accounts`)
endif
ifeq (true, $(shell [ -z "$(AWS_ACCOUNT_ID_MGMT)" ] && [ -z "$(AWS_ACCOUNT_ID_TOOLS)" ] && echo true))
$(info AWS_ACCOUNT_ID_MGMT is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config, run `make devops-setup-aws-accounts`)
endif
ifeq (true, $(shell [ -z "$(AWS_ACCOUNT_ID_TOOLS)" ] && ([ -z "$(AWS_ACCOUNT_ID_MGMT)" ] || [ -z "$(AWS_ACCOUNT_ID_LIVE_PARENT)" ]) && echo true))
$(info AWS_ACCOUNT_ID_TOOLS is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config, run `make devops-setup-aws-accounts`)
endif
ifndef AWS_ACCOUNT_ID_NONPROD
$(info AWS_ACCOUNT_ID_NONPROD is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config, run `make devops-setup-aws-accounts`)
endif
ifndef AWS_ACCOUNT_ID_PROD
$(info AWS_ACCOUNT_ID_PROD is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config, run `make devops-setup-aws-accounts`)
endif

# ==============================================================================
# Check if all the prerequisites are met

ifeq (true, $(shell [ ! -f $(SETUP_COMPLETE_FLAG_FILE) ] && echo true))
ifeq (true, $(shell [ "Darwin" == "$$(uname)" ] && echo true))
# macOS: Xcode Command Line Tools
ifneq (0, $(shell xcode-select -p > /dev/null 2>&1; echo $$?))
$(info )
$(info $(shell tput setaf 4; echo "Installation of the Xcode Command Line Tools has just been triggered automatically..."; tput sgr0))
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the Xcode Command Line Tools"; tput sgr0))
endif
# macOS: Homebrew
ifneq (0, $(shell which brew > /dev/null 2>&1; echo $$?))
$(info )
$(info Run $(shell tput setaf 4; echo '/usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"'; tput sgr0))
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the brew package manager. Copy and paste in your terminal the above command, then execute it"; tput sgr0))
endif
# macOS: GNU Make
ifeq (true, $(shell [ ! -f /usr/local/opt/make/libexec/gnubin/make ] && echo true))
$(info )
$(info Run $(shell tput setaf 4; echo "brew install make"; tput sgr0))
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the GNU make tool. Copy and paste in your terminal the above command, then execute it"; tput sgr0))
endif
ifeq (, $(findstring oneshell, $(.FEATURES)))
$(info )
$(info Run $(shell tput setaf 4; echo "export PATH=$(PATH)"; tput sgr0))
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding make sure GNU make is included in your \$$PATH. Copy and paste in your terminal the above command, then execute it"; tput sgr0))
endif
# macOS: $HOME
ifeq (true, $(shell echo "$(HOME)" | grep -qE '[ ]+' && echo true))
$(info )
$(info The $$HOME variable is set to '$(HOME)')
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding make sure your \$$HOME directory does not include spaces"; tput sgr0))
endif
else
# *NIX: GNU Make
ifeq (, $(findstring oneshell, $(.FEATURES)))
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding make sure your GNU make version supports 'oneshell' feature. On Linux this may mean upgrading to the latest release version"; tput sgr0))
endif
# *NIX: Docker
ifneq (0, $(shell which docker > /dev/null 2>&1; echo $$?))
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install Docker"; tput sgr0))
endif
# *NIX: Docker Compose
ifneq (0, $(shell which docker-compose > /dev/null 2>&1; echo $$?))
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install Docker Compose"; tput sgr0))
endif
endif
endif

# ==============================================================================

.SILENT: \
	_devops-synchronise-select-tag-to-install \
	_devops-test \
	devops-copy \
	devops-get-variable get-variable \
	devops-print-variables show-configuration \
	devops-setup-aws-accounts \
	devops-setup-aws-accounts-for-service \
	devops-switch-aws-accounts \
	devops-test-single \
	devops-test-suite \
	help \
	help-all
