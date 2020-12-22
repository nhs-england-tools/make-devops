include $(VAR_DIR)/platform-texas/v2/account-prod.mk

# ==============================================================================
# Infrastructure variables

INFRASTRUCTURE_STACKS = terraform-state,service-roles,networking

# Terraform module configuration
TERRAFORM_STATE_KEY = $(TERRAFORM_STATE_KEY_SHARED)

# Terraform stacks configuration
TERRAFORM_STATE_BUCKET_NAME = $(TERRAFORM_STATE_STORE)
TERRAFORM_STATE_TABLE_NAME = $(TERRAFORM_STATE_LOCK)
TERRAFORM_NETWORKING_VPC_NAME = $(PROJECT_ID)-$(AWS_ACCOUNT_NAME)
TERRAFORM_NETWORKING_VPC_ID = 2
TERRAFORM_NHSD_IDENTITIES_ACCOUNT_ID = $(AWS_ACCOUNT_ID_IDENTITIES)
