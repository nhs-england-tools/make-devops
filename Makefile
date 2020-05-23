PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build: project-config

start: project-start

stop: project-stop

log: project-log

# ==============================================================================

.SILENT:
