AWS_ACCOUNT_ID := $(AWS_ACCOUNT_ID_NONPROD)
AWS_ACCOUNT_NAME := nonprod

TF_VAR_terraform_platform_state_store = nhsd-texasplatform-terraform-state-store-live-lk8s-$(AWS_ACCOUNT_NAME)

# ==============================================================================

include $(VAR_DIR)/platform-texas/platform-texas-v1.mk
