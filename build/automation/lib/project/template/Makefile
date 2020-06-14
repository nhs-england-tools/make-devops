PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================
# Project targets: Dev workflow

# ==============================================================================
# Project targets: Ops workflow

build: project-config # Build project
	make docker-build NAME=NAME_TEMPLATE_TO_REPLACE

start: project-start # Start project

stop: project-stop # Stop project

log: project-log # Show project logs

test: # Test project
	make start
	make stop

push: # Push project artefacts to the registry
	make docker-push NAME=NAME_TEMPLATE_TO_REPLACE

deploy: project-deploy # Deploy project - mandatory: PROFILE=[name]

clean: # Clean up project

# ==============================================================================
# Supporting targets

create-artefact-repository: ## Create Docker repositories to store artefacts
	make docker-create-repository NAME=NAME_TEMPLATE_TO_REPLACE

# ==============================================================================

.SILENT:
