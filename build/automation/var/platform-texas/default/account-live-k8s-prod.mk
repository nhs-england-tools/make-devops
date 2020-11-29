AWS_ACCOUNT_ID := $(AWS_ACCOUNT_ID_PROD)
AWS_ACCOUNT_NAME := prod

TF_VAR_terraform_platform_state_store = nhsd-texasplatform-terraform-state-store-lk8s-$(AWS_ACCOUNT_NAME)

# ==============================================================================

include $(VAR_DIR)/platform-texas/platform-texas.mk
