include $(VAR_DIR)/platform-texas/platform-texas-revamp.mk

AWS_ACCOUNT_ID = $(or $(AWS_ACCOUNT_ID_TOOLS), $(AWS_ACCOUNT_ID_MGMT))
AWS_ACCOUNT_NAME = tools
