PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

project-config:
	make docker-config

project-build: project-config

project-start:
	make docker-compose-start YML=$(DOCKER_COMPOSE_YML)

project-stop:
	make docker-compose-stop YML=$(DOCKER_COMPOSE_YML)

project-log:
	make docker-compose-log YML=$(DOCKER_COMPOSE_YML)

# ==============================================================================

.SILENT:
