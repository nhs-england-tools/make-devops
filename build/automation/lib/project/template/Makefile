PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================
# Development workflow targets

build: project-config # Build project
	make docker-build NAME=NAME_TEMPLATE_TO_REPLACE

start: project-start # Start project

stop: project-stop # Stop project

log: project-log # Show project logs

test: # Test project
	make start
	make stop

clean: # Clean up project

# ==============================================================================
# Deployment workflow targets

push: ## Push project artefacts to the registry
	make docker-push NAME=NAME_TEMPLATE_TO_REPLACE

deploy: ## Deploy artefacts - mandatory: PROFILE=[name]
	make project-deploy STACK=application PROFILE=$(PROFILE)

provision: ## Provision environment - mandatory: PROFILE=[name]
	make terraform-apply-auto-approve STACK=database PROFILE=$(PROFILE)

# ==============================================================================
# Supporting targets

trust-certificate: ssl-trust-certificate-project

create-artefact-repositories: ## Create repositories to store artefacts
	make docker-create-repository NAME=NAME_TEMPLATE_TO_REPLACE

# ==============================================================================

.SILENT:
