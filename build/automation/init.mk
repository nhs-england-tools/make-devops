help: help-project-flow # Show project development flow targets

help-all: # Show all targets
	@awk 'BEGIN {FS = ":.*?#+ "} /^[ a-zA-Z0-9_-]+:.*? #+ / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

help-dev: # Show development documentation
	# TODO: Show development documentation

help-project-flow: ## Show project development flow targets
	@awk 'BEGIN {FS = ":.*?# "} /^[ a-zA-Z0-9_-]+:.*? # / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

help-project-supporting: ## Show development supporting targets
	@awk 'BEGIN {FS = ":.*?## "} /^[ a-zA-Z0-9_-]+:.*? ## / {printf "\033[36m%-41s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

devops-print-variables: ### Print all the variables
	$(foreach v, $(sort $(.VARIABLES)),
		$(if $(filter-out default automatic, $(origin $v)),
			$(info $v=$($v) ($(value $v)))
		)
	)

devops-test-suite: ### Run the DevOps unit test suite - optional: DEBUG=true
	make _devops-test DEBUG=$(DEBUG) TESTS=" \
		test-file \
		test-ssl \
		test-git \
		test-docker \
		test-aws \
		test-secret \
		test-terraform \
		test-k8s \
		test-jenkins \
		test-techradar \
	"

devops-test-single: ### Run a DevOps single test - mandatory NAME=[test target name]; optional: DEBUG=true
	make _devops-test DEBUG=$(DEBUG) TESTS="$(NAME)"

_devops-test:
	[ "$(AWS_ACCOUNT_ID_LIVE_PARENT)" == 123456789 ] && echo "AWS_ACCOUNT_ID_LIVE_PARENT is not set correctly"
	[ "$(AWS_ACCOUNT_ID_MGMT)" == 123456789 ] && echo "AWS_ACCOUNT_ID_MGMT is not set correctly"
	[ "$(AWS_ACCOUNT_ID_NONPROD)" == 123456789 ] && echo "AWS_ACCOUNT_ID_NONPROD is not set correctly"
	[ "$(AWS_ACCOUNT_ID_PROD)" == 123456789 ] && echo "AWS_ACCOUNT_ID_PROD is not set correctly"
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
	make $$config \
		$(TESTS) \
	>&3 2>&3

devops-test-cleanup: ### Clean up adter the tests
	docker network rm $(DOCKER_NETWORK) 2> /dev/null ||:
	# TODO: Remove older networks that remained after unsuccessful builds

devops-synchronise: ### Synchronise the DevOps automation toolchain scripts used by this project - optional: ALL=true
	function download() {
		cd $(PROJECT_DIR)
		rm -rf \
			$(TMP_DIR)/$(DEVOPS_PROJECT_NAME) \
			.git/modules/build \
			.gitmodules
		git submodule add --force \
			https://github.com/$(DEVOPS_PROJECT_ORG)/$(DEVOPS_PROJECT_NAME).git \
			$$(echo $(abspath $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)) | sed "s;$(PROJECT_DIR);;g")
		tag=$$(make _devops-synchronise-select-tag-to-install)
		cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
		git checkout $$tag
	}
	function sync() {
		cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
		rsync -rav \
			--include=build/ \
			--exclude=docker/docker-compose.yml \
			--exclude=Jenkinsfile \
			build/* \
			$(PROJECT_DIR)/build
		mkdir -p \
			$(PROJECT_DIR)/documentation/adr
		cp -fv documentation/adr/README.md $(PROJECT_DIR)/documentation/adr/README.md
		cp -fv CONTRIBUTING.md $(PROJECT_DIR)/CONTRIBUTING.md
		cp -fv LICENSE.md $(PROJECT_DIR)/build/automation/LICENSE.md
		cp -fv $(DEVOPS_PROJECT_NAME).code-workspace.template $(PROJECT_DIR)/$(PROJECT_NAME).code-workspace.template
		[ ! -f $(PROJECT_DIR)/build/docker/docker-compose.yml ] && cp -v \
			build/docker/docker-compose.yml \
			$(PROJECT_DIR)/build/docker/docker-compose.yml ||:
		[ ! -f $(PROJECT_DIR)/build/Jenkinsfile ] && cp -v \
			build/Jenkinsfile \
			$(PROJECT_DIR)/build/Jenkinsfile ||:
	}
	function version() {
		cd $(TMP_DIR)/$(DEVOPS_PROJECT_NAME)
		tag=$$([ -n "$$(git tag --points-at HEAD)" ] && echo $$(git tag --points-at HEAD) || echo vcommit)
		hash=$$(git rev-parse --short HEAD)
		echo "$${tag:1}-$${hash}" > $(PROJECT_DIR)/build/automation/VERSION
	}
	function cleanup() {
		cd $(PROJECT_DIR)
		rm -rf \
			~/bin/texas-mfa-clear.sh \
			~/bin/texas-mfa.py \
			~/bin/toggle-natural-scrolling.sh \
			$(BIN_DIR)/markdown.pl \
			$(DOCKER_DIR)/Dockerfile.metadata \
			$(ETC_DIR)/platform-texas* \
			$(LIB_DIR)/dev.mk
		rm -rf \
			$(TMP_DIR)/$(DEVOPS_PROJECT_NAME) \
			.git/modules/build \
			.gitmodules
		git reset -- .gitmodules
		git reset -- build/automation/tmp/$(DEVOPS_PROJECT_NAME)
	}
	function commit() {
		cd $(PROJECT_DIR)
		if [ 0 -lt $$(git status -s | wc -l) ]; then
			git add .
			git commit -S -m "Update the DevOps automation toolchain scripts"
		fi
	}
	if [ 0 -lt $$(git status -s | wc -l) ]; then
		echo "ERROR: Please, commit your changes first"
		exit 1
	fi
	cleanup && download && sync && version && cleanup && commit

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

# ==============================================================================
# Project configuration

DEVOPS_PROJECT_ORG := nhsd-ddce
DEVOPS_PROJECT_NAME := make-devops
DEVOPS_PROJECT_DIR := $(abspath $(lastword $(MAKEFILE_LIST))/..)

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
APPLICATION_TEST_DIR := $(abspath $(or $(APPLICATION_TEST_DIR), $(PROJECT_DIR)/test))
CONFIG_DIR := $(abspath $(or $(CONFIG_DIR), $(PROJECT_DIR)/config))
DATA_DIR := $(abspath $(or $(DATA_DIR), $(PROJECT_DIR)/data))
DEPLOYMENT_DIR := $(abspath $(or $(DEPLOYMENT_DIR), $(PROJECT_DIR)/deployment))
GITHOOKS_DIR_REL := $(shell echo $(abspath $(ETC_DIR)/githooks) | sed "s;$(PROJECT_DIR);;g")
INFRASTRUCTURE_DIR := $(abspath $(or $(INFRASTRUCTURE_DIR), $(PROJECT_DIR)/infrastructure))
JQ_PROGS_DIR_REL := $(shell echo $(abspath $(LIB_DIR)/jq) | sed "s;$(PROJECT_DIR);;g")

PROFILE := $(or $(PROFILE), local)
BUILD_ID := $(or $(BUILD_ID), 0)
BUILD_DATE := $(or $(BUILD_DATE), $(shell date -u +"%Y-%m-%dT%H:%M:%S%z"))
BUILD_HASH := $(or $(shell git rev-parse --short HEAD 2> /dev/null ||:), unknown)
BUILD_REPO := $(or $(shell git config --get remote.origin.url 2> /dev/null ||:), unknown)
BUILD_BRANCH := $(or $(shell git rev-parse --abbrev-ref HEAD 2> /dev/null ||:), unknown)
USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)
_TTY := $$([ -t 0 ] && echo "--tty")

GOSS_PATH := $(BIN_DIR)/goss-linux-amd64
SETUP_COMPLETE_FLAG_FILE := $(TMP_DIR)/.make-devops-setup-complete

# ==============================================================================
# `make` configuration

.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:
.NOTPARALLEL:
.ONESHELL:
.PHONY: *
.SHELLFLAGS := -ce
MAKEFLAGS := --no-print-director
PATH := /usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/make/libexec/gnubin:$(BIN_DIR):$(PATH)
SHELL := /bin/bash

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
ifndef PROGRAMME
$(error PROGRAMME is not set in build/automation/var/project.mk)
endif

ifndef TEXAS_SERVICE_TAG
$(error TEXAS_SERVICE_TAG is not set in build/automation/var/project.mk)
endif
ifndef TEXAS_ROLE_PREFIX
$(error TEXAS_ROLE_PREFIX is not set in build/automation/var/project.mk)
endif

ifndef AWS_ACCOUNT_ID_LIVE_PARENT
$(info AWS_ACCOUNT_ID_LIVE_PARENT is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config)
endif
ifndef AWS_ACCOUNT_ID_MGMT
$(info AWS_ACCOUNT_ID_MGMT is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config)
endif
ifndef AWS_ACCOUNT_ID_NONPROD
$(info AWS_ACCOUNT_ID_NONPROD is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config)
endif
ifndef AWS_ACCOUNT_ID_PROD
$(info AWS_ACCOUNT_ID_PROD is not set in ~/.dotfiles/oh-my-zsh/plugins/make-devops/aws-platform.zsh or in your CI config)
endif

# ==============================================================================
# Check if all the prerequisites are met

ifeq (true, $(shell [ ! -f $(SETUP_COMPLETE_FLAG_FILE) ] && echo true))
ifeq (true, $(shell [ "Darwin" == "$$(uname)" ] && echo true))
# macOS: Xcode Command Line Tools
ifneq (0, $(shell xcode-select -p > /dev/null 2>&1; echo $$?))
$(info )
$(info Installation of the Xcode Command Line Tools has just been triggered automatically...)
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the Xcode Command Line Tools"; tput sgr0))
endif
# macOS: Homebrew
ifneq (0, $(shell which brew > /dev/null 2>&1; echo $$?))
$(info )
$(info /usr/bin/ruby -e "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)")
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the brew package manager. Copy and paste in your terminal the above command, then execute it"; tput sgr0))
endif
# macOS: GNU Make
ifeq (true, $(shell [ ! -f /usr/local/opt/make/libexec/gnubin/make ] && echo true))
$(info )
$(info brew install make)
$(info )
$(error $(shell tput setaf 1; echo "ERROR: Please, before proceeding install the GNU make tool. Copy and paste in your terminal the above command, then execute it"; tput sgr0))
endif
ifeq (, $(findstring oneshell, $(.FEATURES)))
$(info )
$(info export PATH=$(PATH))
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
	devops-print-variables \
	devops-test-single \
	devops-test-suite \
	_devops-synchronise-select-tag-to-install \
	_devops-test
