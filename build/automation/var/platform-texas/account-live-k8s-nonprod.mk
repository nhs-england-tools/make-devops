AWS_ACCOUNT_ID := $(AWS_ACCOUNT_ID_NONPROD)
AWS_ACCOUNT_NAME := nonprod

TEXAS_K8S_KUBECONFIG_FILE := nhsd-texasplatform-kubeconfig-lk8s-nonprod/live-leks-cluster_kubeconfig

# ==============================================================================

include $(VAR_DIR)/platform-texas/platform-texas.mk
