project-config: ### Configure project environment
	make \
		git-config \
		docker-config

project-start: ### Start Docker Compose
	make docker-compose-start

project-stop: ### Stop Docker Compose
	make docker-compose-stop

project-log: ### Print log from Docker Compose
	make docker-compose-log

project-deploy: ### Deploy application service stack to the Kubernetes cluster - mandatory: PROFILE=[profile name]
	make k8s-deploy STACK=$(or $(NAME), service)

# ==============================================================================

project-create-profile: ### Create profile file - mandatory: NAME=[profile name]
	if [ ! -f $(VAR_DIR)/profile/$(NAME).mk ]; then
		cp $(VAR_DIR)/profile/dev.mk.default $(VAR_DIR)/profile/$(NAME).mk
	fi

project-create-image: ### Create image from template - mandatory: NAME=[image name],TEMPLATE=[library template image name]
	make -s docker-create-from-template NAME=$(NAME) TEMPLATE=$(TEMPLATE)

project-create-deployment: ### Create deployment from template - mamdatory: NAME=[deployment name],PROFILE=[profile name]
	rm -rf $(DEPLOYMENT_DIR)/stacks/$(NAME)
	make -s k8s-create-base-from-template STACK=$(NAME)
	make -s k8s-create-overlay-from-template STACK=$(NAME) PROFILE=$(PROFILE)
	make project-create-profile NAME=$(PROFILE)

project-create-infrastructure: ### Create infrastructure from template - mamdatory: NAME=[infrastructure name],TEMPLATE=[library template infrastructure name]
	rm -rf $(INFRASTRUCTURE_DIR)/modules/$(TEMPLATE)
	make -s k8s-create-module-from-template TEMPLATE=$(TEMPLATE)
	rm -rf $(INFRASTRUCTURE_DIR)/stacks/$(NAME)
	make -s k8s-create-stack-from-template NAME=$(NAME) TEMPLATE=$(TEMPLATE)

project-create-pipline: ### Create pipline
	make -s jenkins-create-pipline-from-template

# ==============================================================================

.SILENT: \
	project-create-deployment \
	project-create-image \
	project-create-pipline
