TERRAFORM_DIR = $(PROJECT_DIR)/infrastructure/stacks
TERRAFORM_DIR_REL = $(shell echo $(TERRAFORM_DIR) | sed "s;$(PROJECT_DIR);;g")
TERRAFORM_STATE_KEY = $(PROJECT_GROUP)-$(PROJECT_NAME)/$(PROFILE)
TERRAFORM_STATE_LOCK = $(or $(TEXAS_TERRAFORM_STATE_LOCK), terraform-service-state-lock-$(PROFILE))
TERRAFORM_STATE_STORE = $(or $(TEXAS_TERRAFORM_STATE_STORE), terraform-service-state-store-$(PROFILE))

# ==============================================================================

terraform-apply-auto-approve: ### Set up infrastructure - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name],INIT=false,OPTS=[Terraform options]
	make terraform-apply \
		STACKS="$(STACKS)" \
		CMD="apply" \
		OPTS="-auto-approve $(OPTS)"

terraform-apply: ### Set up infrastructure - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name],INIT=false,OPTS=[Terraform options]
	make _terraform-stacks \
		STACKS="$(STACKS)" \
		CMD="apply $(OPTS)"

terraform-destroy-auto-approve: ### Tear down infrastructure - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name],INIT=false,OPTS=[Terraform options]
	make terraform-destroy \
		STACKS="$(STACKS)" \
		CMD="destroy" \
		OPTS="-auto-approve $(OPTS)"

terraform-destroy: ### Tear down infrastructure - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name],INIT=false,OPTS=[Terraform options]
	make _terraform-stacks \
		STACKS="$(STACKS)" \
		CMD="destroy $(OPTS)"

terraform-plan: ### Tear down infrastructure - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name],INIT=false,OPTS=[Terraform options]
	make _terraform-stacks \
		STACKS="$(STACKS)" \
		CMD="plan $(OPTS)"

terraform-unlock: ### Remove state lock - mandatory: STACKS=[comma-separated names],ID=[lock ID]; optional: PROFILE=[name],INIT=false,OPTS=-force
	make _terraform-stacks \
		STACKS="$(STACKS)" \
		CMD="force-unlock $(ID) $(OPTS)"

terraform-fmt: ### Format Terraform code - optional: DIR,OPTS=[Terraform options]
	make docker-run-terraform \
		CMD="fmt -recursive $(OPTS)"

# ==============================================================================

terraform-export-variables-aws: ### Get AWS environment variables as TF_VAR_[name] variables - returns: [variables export]
	exports=$$(make terraform-export-variables-from-shell PATTERN="^(AWS|aws)_")
	echo "$$exports"

terraform-export-variables-from-secret: ### Get secret as TF_VAR_[name] variables - mandatory: NAME=[secret name]; returns: [variables export]
	if [ -n "$(NAME)" ]; then
		secret=$$(make secret-fetch NAME=$(NAME))
		exports=$$(make terraform-export-variables-from-json JSON="$$secret")
		echo "$$exports"
	fi

terraform-export-variables-from-shell: ### Convert environment variables as TF_VAR_[name] variables - mandatory: VARS=[comma-separated environment variable names]|PATTERN="^AWS_"; returns: [variables export]
	if [ -n "$(PATTERN)" ]; then
		for str in $$(env | grep -E "$(PATTERN)"); do
			key=$$(cut -d "=" -f1 <<<"$$str" | tr '[:upper:]' '[:lower:]')
			value=$$(cut -d "=" -f2- <<<"$$str")
			echo "export TF_VAR_$${key}=$${value}"
		done
	fi
	if [ -n "$(VARS)" ]; then
		for str in $$(echo "$(VARS)" | sed 's/,/\n/g'); do
			key=$$(echo "$$str" | tr '[:upper:]' '[:lower:]')
			value=$$(cut -d "=" -f2- <<<"$$str")
			echo "export TF_VAR_$${key}=$${value}"
		done
	fi

terraform-export-variables-from-json: ### Convert JSON to Terraform input exported as TF_VAR_[name] variables - mandatory: JSON='{"key":"value"}'|JSON="$$(echo '$(JSON)')"; returns: [variables export]
	for str in $$(echo '$(JSON)' | make -s docker-run-tools CMD="jq -rf $(JQ_DIR_REL)/json-to-env-vars.jq"); do
		key=$$(cut -d "=" -f1 <<<"$$str" | tr '[:upper:]' '[:lower:]')
		value=$$(cut -d "=" -f2- <<<"$$str")
		echo "export TF_VAR_$${key}=$${value}"
	done

# ==============================================================================

_terraform-stacks: ### Set up infrastructure for a given list of stacks - mandatory: STACKS=[comma-separated names],CMD=[Terraform command]; optional: INIT=false,PROFILE=[name]
	for stack in $$(echo $(STACKS) | tr "," "\n"); do
		make _terraform-stack STACK="$$stack" CMD="$(CMD)"
	done

_terraform-stack: ### Set up infrastructure for a single stack - mandatory: STACK=[name],CMD=[Terraform command]; optional: INIT=false,PROFILE=[name]
	if ! [[ "$(INIT)" =~ ^(false|no|n|off|0|FALSE|NO|N|OFF)$$ ]]; then
		make _terraform-reinitialise DIR="$(DIR)" STACK="$(STACK)"
	fi
	eval "$$(make terraform-export-variables-aws)"
	make docker-run-terraform DIR="$(TERRAFORM_DIR)/$(STACK)" CMD="$(CMD)"

_terraform-reinitialise: ### Reinitialise infrastructure state - mandatory: STACK=[name]; optional: PROFILE=[name]
	rm -rf $(DIR)/$(STACK)/*terraform.tfstate*
	make _terraform-initialise STACK="$(STACK)"

_terraform-initialise: ### Initialise infrastructure state - mandatory: STACK=[name]; optional: PROFILE=[name]
	make docker-run-terraform DIR="$(TERRAFORM_DIR)/$(STACK)" CMD=" \
		init \
			-backend-config="bucket=$(TERRAFORM_STATE_STORE)" \
			-backend-config="dynamodb_table=$(TERRAFORM_STATE_LOCK)" \
			-backend-config="encrypt=true" \
			-backend-config="key=$(PROJECT_GROUP_SHORT)-$(PROJECT_NAME)-$(STACK)-$(PROFILE)/terraform.state" \
			-backend-config="region=$(AWS_REGION)" \
	"

# ==============================================================================

terraform-delete-state: ### Delete the Terraform state - mandatory: STACKS=[comma-separated names]; optional: PROFILE=[name]
	for stack in $$(echo $(STACKS) | tr "," "\n"); do
		make aws-delete-terraform-state-from-s3 STACK="$$stack"
		make aws-delete-terraform-state-from-dynamodb STACK="$$stack"
	done

_terraform-delete-state-store: ### Delete Terraform state store - mandatory: STACK=[name]; optional: PROFILE=[name]
	# TODO: Use Docker tools image to run the AWS CLI command
	aws s3 rm \
		s3://$(TERRAFORM_STATE_STORE)/$(TERRAFORM_STATE_KEY)/$(STACK) \
		--recursive

_terraform-delete-state-lock: ### Delete Terraform state lock - mandatory: STACK=[name]; optional: PROFILE=[name]
	# TODO: Use Docker tools image to run the AWS CLI command
	aws dynamodb delete-item \
		--table-name $(TERRAFORM_STATE_LOCK) \
		--key '{"LockID": {"S": "$(TERRAFORM_STATE_STORE)/$(TERRAFORM_STATE_KEY)/$(STACK)/terraform.state-md5"}}'

terraform-clean: ### Clean Terraform files
	find $(TERRAFORM_DIR) -type d -name '.terraform' -print0 | xargs -0 rm -rfv
	find $(TERRAFORM_DIR) -type f -name '*terraform.tfstate*' -print0 | xargs -0 rm -rfv

# ==============================================================================

.SILENT: \
	terraform-export-variables-aws \
	terraform-export-variables-from-json \
	terraform-export-variables-from-secret \
	terraform-export-variables-from-shell
