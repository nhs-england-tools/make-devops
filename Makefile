PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

config: project-config

code-format:
	make -s python-code-format FILES=build/automation/bin/*.py

code-check:
	make -s python-code-check FILES=build/automation/bin/*.py

# ==============================================================================

.SILENT: \
	code-check \
	code-format
