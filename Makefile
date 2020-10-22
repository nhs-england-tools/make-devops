PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

config: project-config

code-format:
	make -s python-code-format FILES=build/automation/bin/*.py

code-check:
	make -s python-code-check FILES=build/automation/bin/*.py

# ==============================================================================
# Supporting targets

create-deployment-resources: ## Create all the pipeline deployment supporting resources - mandatory: PROFILE=[name]
	make secret-create \
		NAME=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-$(PROFILE)/deployment \
		VARS=SLACK_WEBHOOK_URL

# ==============================================================================
# Pipeline targets

pipeline-send-notification:
	eval "$$(make aws-assume-role-export-variables)"
	eval "$$(make secret-fetch-and-export-variables NAME=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME_SHORT)-$(PROFILE)/deployment)"
	make slack-it

# ==============================================================================

.SILENT: \
	code-check \
	code-format
