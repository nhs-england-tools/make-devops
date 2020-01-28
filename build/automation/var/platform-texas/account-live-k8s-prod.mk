AWS_ACCOUNT_ID := $(AWS_ACCOUNT_ID_PROD)
AWS_ACCOUNT_NAME := prod

TEXAS_K8S_KUBECONFIG_FILE := nhsd-texasplatform-kubeconfig-lk8s-prod/live-leks-cluster_kubeconfig

# ==============================================================================

include $(VAR_DIR)/platform-texas/platform-texas.mk
