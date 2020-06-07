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

project-deploy: ### Deploy application service stack to the Kubernetes cluster - mandatory: PROFILE=[name]
	make k8s-deploy STACK=service

# ==============================================================================

project-create-image: ### Create Docker image file structure - mandatory: NAME,TEMPLATE
	mkdir -p $(PROJECT_DIR)/build/docker
	make docker-create-from-template NAME=$(NAME) TEMPLATE=$(TEMPLATE)
	if [ ! -f $(PROJECT_DIR)/build/docker/docker-compose.yml ]; then
		cp -rfv \
			$(PROJECT_DIR)/build/automation/lib/project/template/build/docker/docker-compose.yml \
			$(PROJECT_DIR)/build/docker
	fi

project-create-jenkins-pipline: ### Create Jenkins pipline
	if [ ! -f $(PROJECT_DIR)/build/Jenkinsfile ]; then
		cp -rfv \
			$(PROJECT_DIR)/build/automation/lib/project/template/build/Jenkinsfile \
			$(PROJECT_DIR)/build
	fi
