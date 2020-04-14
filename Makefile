PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

project-config:
	make docker-config

project-build: project-config

project-start:
	make docker-compose-start

project-stop:
	make docker-compose-stop

project-log:
	make docker-compose-log

# ==============================================================================

.SILENT:
