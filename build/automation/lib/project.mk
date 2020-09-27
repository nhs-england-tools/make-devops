PROJECT_CONFIG_TIMESTAMP_FILE = $(TMP_DIR)/project-config-timestamp
#PROJECT_CONFIG_TARGET
#PROJECT_CONFIG_TIMESTAMP
#PROJECT_CONFIG_FORCE

project-config: ### Configure project environment
	make \
		git-config \
		docker-config
	if [ ! -f $(PROJECT_DIR)/project.code-workspace ]; then
		cp -fv $(LIB_DIR)/project/template/project.code-workspace $(PROJECT_DIR)
	fi
	# Make sure project's SSL certificate is created
	if [ ! -f $(SSL_CERTIFICATE_DIR)/certificate.pem ]; then
		make ssl-generate-certificate-project
		[ $(PROJECT_NAME) != "make-devops" ] && rm -f $(SSL_CERTIFICATE_DIR)/.gitignore
	fi
	# Re-configure developer's environment on demand
	if [ -n "$(PROJECT_CONFIG_TIMESTAMP)" ] && ([ ! -f $(PROJECT_CONFIG_TIMESTAMP_FILE) ] || [ $(PROJECT_CONFIG_TIMESTAMP) -gt $$(cat $(PROJECT_CONFIG_TIMESTAMP_FILE)) ]) && [ $(BUILD_ID) -eq 0 ]; then
		if [[ ! "$(PROJECT_CONFIG_FORCE)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
			read -p "Your development environment needs to be re-configured, would you like to proceed? (yes or no) " answer
			if [[ ! "$$answer" =~ ^(yes|y|YES|Y)$$ ]]; then
				exit 1
			fi
		fi
		make $(PROJECT_CONFIG_TARGET)
		echo $(BUILD_TIMESTAMP) > $(PROJECT_CONFIG_TIMESTAMP_FILE)
	fi

project-start: ### Start Docker Compose
	make docker-compose-start

project-stop: ### Stop Docker Compose
	make docker-compose-stop

project-log: ### Print log from Docker Compose
	make docker-compose-log

project-deploy: ### Deploy application service stack to the Kubernetes cluster - mandatory: PROFILE=[profile name]
	make k8s-deploy STACK=$(or $(NAME), service)

project-document-infrastructure: ### Generate infrastructure diagram - optional: FIN=[Python file path, defaults to infrastructure/diagram.py],FOUT=[PNG file path, defaults to documentation/Infrastructure_Diagram]
	make docker-run-tools CMD="python \
		$(or $(FIN), $(INFRASTRUCTURE_DIR_REL)/diagram.py) \
		$(or $(FOUT), $(DOCUMENTATION_DIR_REL)/Infrastructure_Diagram) \
	"

# ==============================================================================

project-tag-as-release-candidate: ### Tag release candidate - mandatory: ARTEFACT|ARTEFACTS=[comma-separated image names]; optional: COMMIT=[git commit hash, defaults to master]
	commit=$(or $(COMMIT), master)
	make git-tag-create-release-candidate COMMIT=$$commit
	tag=$$(make git-tag-get-release-candidate COMMIT=$$commit)
	for image in $$(echo $(or $(ARTEFACTS), $(ARTEFACT)) | tr "," "\n"); do
		make docker-image-find-and-tag-as \
			TAG=$$tag \
			IMAGE=$$image \
			COMMIT=$$commit
	done

project-tag-as-environment-deployment: ### Tag environment deployment - mandatory: ARTEFACT|ARTEFACTS=[comma-separated image names],PROFILE=[profile name]; optional: COMMIT=[git release candidate tag name, defaults to master]
	[ $(PROFILE) = local ] && (echo "ERROR: Please, specify the PROFILE"; exit 1)
	commit=$(or $(COMMIT), master)
	make git-tag-create-environment-deployment COMMIT=$$commit PROFILE=$(PROFILE)
	tag=$$(make git-tag-get-environment-deployment COMMIT=$$commit PROFILE=$(PROFILE) )
	for image in $$(echo $(or $(ARTEFACTS), $(ARTEFACT)) | tr "," "\n"); do
		make docker-image-find-and-tag-as \
			TAG=$$tag \
			IMAGE=$$image \
			COMMIT=$$commit
	done

# ==============================================================================

project-create-profile: ### Create profile file - mandatory: NAME=[profile name]
	cp -fv $(VAR_DIR_REL)/profile/dev.mk.default $(VAR_DIR_REL)/profile/$(NAME).mk

project-create-contract-test: ### Create contract test project structure from template
	rm -rf $(APPLICATION_TEST_DIR)/contract
	make -s test-create-contract

project-create-image: ### Create image from template - mandatory: NAME=[image name],TEMPLATE=[library template image name]
	make -s docker-create-from-template NAME=$(NAME) TEMPLATE=$(TEMPLATE)

project-create-deployment: ### Create deployment from template - mandatory: STACK=[deployment name],PROFILE=[profile name]
	rm -rf $(DEPLOYMENT_DIR)/stacks/$(STACK)
	make -s k8s-create-base-from-template STACK=$(STACK)
	make -s k8s-create-overlay-from-template STACK=$(STACK) PROFILE=$(PROFILE)
	make project-create-profile NAME=$(PROFILE)

project-create-infrastructure: ### Create infrastructure from template - mandatory: STACK=[infrastructure name],TEMPLATE=[library template infrastructure name]
	make -s terraform-create-module-from-template TEMPLATE=$(TEMPLATE)
	make -s terraform-create-stack-from-template NAME=$(STACK) TEMPLATE=$(TEMPLATE)
	cp -fv $(LIB_DIR_REL)/project/template/infrastructure/diagram.py $(INFRASTRUCTURE_DIR_REL)/diagram.py

project-create-pipeline: ### Create pipeline
	make -s jenkins-create-pipeline-from-template

# ==============================================================================

.SILENT: \
	project-create-contract-test \
	project-create-deployment \
	project-create-image \
	project-create-infrastructure \
	project-create-pipeline \
	project-create-profile
