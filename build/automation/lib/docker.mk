DOCKER_COMPOSER_VERSION := $(or $(DOCKER_COMPOSER_VERSION), 1.9.1)
DOCKER_DATA_VERSION := $(or $(DOCKER_DATA_VERSION),)
DOCKER_DOTNET_VERSION := $(or $(DOCKER_DOTNET_VERSION), 3.0-alpine)
DOCKER_ELASTICSEARCH_VERSION := $(or $(DOCKER_ELASTICSEARCH_VERSION), 6.7.2)
DOCKER_GRADLE_VERSION := $(or $(DOCKER_GRADLE_VERSION), 5.6.4-jdk11)
DOCKER_MAVEN_VERSION := $(or $(DOCKER_MAVEN_VERSION), 3.6.2-jdk-14)
DOCKER_NGINX_VERSION := $(or $(DOCKER_NGINX_VERSION), 1.16.1-alpine)
DOCKER_NODE_VERSION := $(or $(DOCKER_NODE_VERSION), 10.16.3)
DOCKER_OPENJDK_VERSION := $(or $(DOCKER_OPENJDK_VERSION), 14-jdk-slim)
DOCKER_POSTGRES_VERSION := $(or $(DOCKER_POSTGRES_VERSION), 11.4)
DOCKER_PYTHON_VERSION := $(or $(DOCKER_PYTHON_VERSION), 3.8.0-alpine)
DOCKER_TERRAFORM_VERSION := $(or $(DOCKER_TERRAFORM_VERSION), 0.12.13)
DOCKER_TOOLS_VERSION := $(or $(DOCKER_TOOLS_VERSION), 1.0.0)

DOCKER_BROWSER_DEBUG := $(or $(DOCKER_BROWSER_DEBUG), -debug)
DOCKER_NETWORK = $(PROJECT_GROUP)/$(BUILD_ID)
DOCKER_REGISTRY = $(AWS_ECR)/$(PROJECT_GROUP)/$(PROJECT_NAME)

# ==============================================================================

docker-config: ### Configure Docker networking
	docker network create $(DOCKER_NETWORK) 2> /dev/null ||:

docker-image: ### Build Docker image - mandatory: NAME; optional: VERSION,NAME_AS=[new name]
	make NAME=$(NAME) \
		docker-create-dockerfile \
		docker-set-image-version VERSION=$(VERSION)
	docker build --rm \
		--build-arg IMAGE=$(DOCKER_REGISTRY)/$(NAME) \
		--build-arg VERSION=$$(cat $(DOCKER_DIR)/$(NAME)/.version) \
		--build-arg BUILD_ID=$(BUILD_ID) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_HASH=$(BUILD_HASH) \
		--build-arg BUILD_REPO=$(BUILD_REPO) \
		$(BUILD_OPTS) \
		--file $(DOCKER_DIR)/$(NAME)/Dockerfile.effective \
		--tag $(DOCKER_REGISTRY)/$(NAME):$$(cat $(DOCKER_DIR)/$(NAME)/.version) \
		$(DOCKER_DIR)/$(NAME)
	docker tag \
		$(DOCKER_REGISTRY)/$(NAME):$$(cat $(DOCKER_DIR)/$(NAME)/.version) \
		$(DOCKER_REGISTRY)/$(NAME):latest
	docker rmi --force $$(docker images | grep "<none>" | awk '{ print $$3 }') 2> /dev/null ||:
	make docker-image-keep-latest-only NAME=$(NAME)
	make techradar-inspect-image NAME=$(NAME)
	if [ -n "$(NAME_AS)" ]; then
		docker tag \
			$(DOCKER_REGISTRY)/$(NAME):$$(cat $(DOCKER_DIR)/$(NAME)/.version) \
			$(DOCKER_REGISTRY)/$(NAME_AS):$$(cat $(DOCKER_DIR)/$(NAME)/.version)
		docker tag \
			$(DOCKER_REGISTRY)/$(NAME):latest \
			$(DOCKER_REGISTRY)/$(NAME_AS):latest
		make docker-image-keep-latest-only NAME=$(NAME_AS)
	fi
	docker image inspect $(DOCKER_REGISTRY)/$(NAME):latest --format='{{.Size}}'

docker-image-keep-latest-only: ### Remove other images than latest - mandatory: NAME
	docker rmi --force $$( \
		docker images --filter=reference="$(DOCKER_REGISTRY)/$(NAME):*" --quiet | \
			grep -v $$(docker images --filter=reference="$(DOCKER_REGISTRY)/$(NAME):latest" --quiet) \
	) 2> /dev/null ||:

docker-login: ### Log into the Docker registry
	$$(aws ecr get-login --region $(AWS_REGION) --no-include-email)

docker-create-repository: ### Create Docker repository to store an image - mandatory: NAME
	aws ecr create-repository --repository-name $(PROJECT_GROUP)/$(NAME)

docker-push: ### Push Docker image - mandatory: NAME
	docker push $(DOCKER_REGISTRY)/$(NAME):$$(cat $(DOCKER_DIR)/$(NAME)/.version)
	docker push $(DOCKER_REGISTRY)/$(NAME):latest

docker-pull: ### Pull Docker image - mandatory: NAME,TAG
	docker pull $(DOCKER_REGISTRY)/$(NAME):$(TAG)

docker-tag: ### Tag latest or provide arguments - mandatory: NAME,TAG|[SOURCE,TARGET]
	if [ -n "$(SOURCE)" ] && [ -n "$(TARGET)" ]; then
		docker tag \
			$(DOCKER_REGISTRY)/$(NAME):$(SOURCE) \
			$(DOCKER_REGISTRY)/$(NAME):$(TARGET)
	elif [ -n "$(TAG)" ]; then
		docker tag \
			$(DOCKER_REGISTRY)/$(NAME):latest \
			$(DOCKER_REGISTRY)/$(NAME):$(TAG)
	fi

docker-clean: ### Clean Docker files
	find $(DOCKER_DIR) -type f -name '.version' -print0 | xargs -0 rm -v 2> /dev/null ||:
	find $(DOCKER_DIR) -type f -name 'Dockerfile.effective' -print0 | xargs -0 rm -v 2> /dev/null ||:

docker-prune: docker-clean ### Clean Docker resources
	docker rmi --force $$(docker images | grep $(DOCKER_REGISTRY) | awk '{ print $$3 }') 2> /dev/null ||:
	docker network rm $(DOCKER_NETWORK) 2> /dev/null ||:

# ==============================================================================

docker-create-dockerfile: ### Create effective Dockerfile - mandatory: NAME
	dir=$$(pwd)
	cd $(DOCKER_DIR)/$(NAME)
	cat Dockerfile ../Dockerfile.metadata > Dockerfile.effective
	sed -i " \
		s/FROM nginx:latest/FROM nginx:${DOCKER_NGINX_VERSION}/g; \
		s/FROM openjdk:latest/FROM openjdk:${DOCKER_OPENJDK_VERSION}/g; \
		s/FROM postgres:latest/FROM postgres:${DOCKER_POSTGRES_VERSION}/g; \
		s/FROM python:latest/FROM python:${DOCKER_PYTHON_VERSION}/g; \
	" Dockerfile.effective
	cd $$dir

docker-get-image-version: ### Get effective Docker image version - mandatory: NAME
	cat $(DOCKER_DIR)/$(NAME)/.version

docker-set-image-version: ### Set effective Docker image version - mandatory: NAME; optional: VERSION
	if [ -n "$(VERSION)" ]; then
		echo $(VERSION) > $(DOCKER_DIR)/$(NAME)/.version
	else
		echo $$(cat $(DOCKER_DIR)/$(NAME)/VERSION) | \
			sed "s/YYYY/$$(date --date=$(BUILD_DATE) -u +"%Y")/g" | \
			sed "s/mm/$$(date --date=$(BUILD_DATE) -u +"%m")/g" | \
			sed "s/dd/$$(date --date=$(BUILD_DATE) -u +"%d")/g" | \
			sed "s/HH/$$(date --date=$(BUILD_DATE) -u +"%H")/g" | \
			sed "s/MM/$$(date --date=$(BUILD_DATE) -u +"%M")/g" | \
			sed "s/ss/$$(date --date=$(BUILD_DATE) -u +"%S")/g" | \
			sed "s/hash/$$(git rev-parse --short HEAD)/g" \
		> $(DOCKER_DIR)/$(NAME)/.version
	fi

# ==============================================================================

docker-image-start: ### Start container - mandatory: NAME; optional: CMD,DIR,ARGS
	docker run --interactive $(_TTY) $$(echo $(ARGS) | grep -- "--attach" > /dev/null 2>&1 && : || echo "--detach") \
		--name $(NAME)-$(BUILD_HASH)-$(BUILD_ID) \
		--env PROFILE=$(PROFILE) \
		--env-file <(env | grep "^AWS_") \
		--env-file <(env | grep "^TF_VAR_") \
		--env-file <(env | grep "^SERVICE_") \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$$(echo $(ARGS) | sed -e "s/--attach//g") \
		$(DOCKER_REGISTRY)/$(NAME):latest \
		$(CMD)

docker-image-stop: ### Stop container - mandatory: NAME
	docker stop $(NAME)-$(BUILD_HASH)-$(BUILD_ID) 2> /dev/null ||:
	docker rm --force --volumes $(NAME)-$(BUILD_HASH)-$(BUILD_ID) 2> /dev/null ||:

docker-image-log: ### Log output of a container - mandatory: NAME
	docker logs --follow $(NAME)-$(BUILD_HASH)-$(BUILD_ID)

docker-image-bash: ### Bash into a container - mandatory: NAME
	docker exec --interactive $(_TTY) --user root \
		$(NAME)-$(BUILD_HASH)-$(BUILD_ID) \
		bash --login || \
	docker exec --interactive $(_TTY) --user root \
		$(NAME)-$(BUILD_HASH)-$(BUILD_ID) \
		sh --login ||:

docker-image-clean: docker-image-stop ### Clean up container and image resources - mandatory: NAME
	docker rmi --force $$(docker images --filter=reference="$(DOCKER_REGISTRY)/$(NAME):*" --quiet) 2> /dev/null ||:
	rm -fv \
		$(DOCKER_DIR)/$(NAME)/.version \
		$(DOCKER_DIR)/$(NAME)/$(NAME)-*-image.tar.gz \
		$(DOCKER_DIR)/$(NAME)/Dockerfile.effective

docker-image-save: ### Save image as a flat file - mandatory: NAME; optional: TAG
	tag=$(TAG)
	if [ -z "$$tag" ]; then
		tag=$$(cat $(DOCKER_DIR)/$(NAME)/.version)
	fi
	docker save $(DOCKER_REGISTRY)/$(NAME):$$tag | gzip > $(DOCKER_DIR)/$(NAME)/$(NAME)-$$tag-image.tar.gz

docker-image-load: ### Load image from a flat file - mandatory: NAME; optional: TAG
	tag=$(TAG)
	if [ -z "$$tag" ]; then
		tag=$$(cat $(DOCKER_DIR)/$(NAME)/.version)
	fi
	gunzip -c $(DOCKER_DIR)/$(NAME)/$(NAME)-$$tag-image.tar.gz | docker load

# ==============================================================================

docker-compose-start: ### Start Docker Compose - mandatory: YML=[docker-compose.yml]
	make docker-config
	docker-compose \
		--file $(YML) \
		up --no-build --remove-orphans --detach

docker-compose-stop: ### Stop Docker Compose - mandatory: YML=[docker-compose.yml]
	docker-compose \
		--file $(YML) \
		stop
	docker rm --force --volumes $$(docker ps --all --quiet) 2> /dev/null ||:

docker-compose-log: ### Log Docker Compose output - mandatory: YML=[docker-compose.yml]; optional: DO_NOT_FOLLOW=true
	docker-compose \
		--file $(YML) \
		logs $$(echo $(DO_NOT_FOLLOW) | grep -E 'true|yes|y|on|1|TRUE|YES|Y|ON' > /dev/null 2>&1 && : || echo "--follow")

# ==============================================================================

docker-run-composer: ### Run composer container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo composer:$(DOCKER_COMPOSER_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name composer-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--volume ~/.composer:/tmp \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-data: ### Run data container - mandatory: CMD; optional: ENGINE=postgres|msslq|mysql,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo $(DOCKER_REGISTRY)/data:$(DOCKER_DATA_VERSION))
	engine=$$([ -z "$(ENGINE)" ] && echo postgres || echo "$(ENGINE)")
	if [ "$$engine" == postgres ]; then
		if [ -z "$$(docker images --filter=reference="$$image" --quiet)" ]; then
			make docker-image NAME=data
		fi
		docker run --interactive $(_TTY) --rm \
			--name data-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep "^AWS_" | grep -v '=$$') \
			--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
			--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env DB_HOST=$(DB_HOST) \
			--env DB_PORT=$(DB_PORT) \
			--env DB_NAME=$(DB_NAME) \
			--env DB_MASTER_USERNAME=$(DB_MASTER_USERNAME) \
			--env DB_MASTER_PASSWORD=$(DB_MASTER_PASSWORD) \
			--env DB_USERNAME=$(DB_USERNAME) \
			--env DB_PASSWORD=$(DB_PASSWORD) \
			--env PROFILE=$(PROFILE) \
			--volume $(PROJECT_DIR):/project \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(DIR) \
			$(ARGS) \
			$$image \
				$(CMD)
	fi

docker-run-dotnet: ### Run dotnet container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo mcr.microsoft.com/dotnet/core/sdk:$(DOCKER_DOTNET_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name dotnet-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			dotnet $(CMD)

docker-run-gradle: ### Run gradle container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo gradle:$(DOCKER_GRADLE_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name gradle-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env GRADLE_USER_HOME=/home/gradle/.gradle \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--volume ~/.gradle:/home/gradle/.gradle \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-mvn: ### Run maven container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo maven:$(DOCKER_MAVEN_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name mvn-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env MAVEN_CONFIG=/var/maven/.m2 \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--volume ~/.m2:/var/maven/.m2 \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			/bin/sh -c " \
				mvn -Duser.home=/var/maven $(CMD) \
			"

docker-run-node: ### Run node container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo node:$(DOCKER_NODE_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name node-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--volume ~/.cache:/home/default/.cache \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			/bin/sh -c " \
				groupadd default -g $$(id -g) 2> /dev/null ||: && \
				useradd default -u $$(id -u) -g $$(id -g) 2> /dev/null ||: && \
				chown $$(id -u):$$(id -g) /home/\$$(id -nu $$(id -u)) && \
				su \$$(id -nu $$(id -u)) -c 'cd /project/$(DIR); $(CMD)' \
			"

docker-run-python: ### Run python container - mandatory: CMD; optional: SH=true,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo python:$(DOCKER_PYTHON_VERSION))
	if [[ ! "$(SH)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		docker run --interactive $(_TTY) --rm \
			--name python-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep "^AWS_" | grep -v '=$$') \
			--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
			--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--env PROFILE=$(PROFILE) \
			--volume $(PROJECT_DIR):/project \
			--volume ~/.python/pip/cache:/tmp/.cache/pip \
			--volume ~/.python/pip/packages:/tmp/.packages \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(DIR) \
			$(ARGS) \
			$$image \
				$(CMD)
	else
		docker run --interactive $(_TTY) --rm \
			--name python-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep "^AWS_" | grep -v '=$$') \
			--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
			--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--env PROFILE=$(PROFILE) \
			--volume $(PROJECT_DIR):/project \
			--volume ~/.python/pip/cache:/tmp/.cache/pip \
			--volume ~/.python/pip/packages:/tmp/.packages \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(DIR) \
			$(ARGS) \
			$$image \
				/bin/sh -c " \
					$(CMD) \
				"
	fi

docker-run-terraform: ### Run terraform container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo hashicorp/terraform:$(DOCKER_TERRAFORM_VERSION))
	docker run --interactive $(_TTY) --rm \
		--name terraform-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep "^AWS_" | grep -v '=$$') \
		--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
		--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
		--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env PROFILE=$(PROFILE) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(DIR) \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-tools: ### Run tools container - mandatory: CMD; optional: SH=true,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file]
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo $(DOCKER_REGISTRY)/tools:$(DOCKER_TOOLS_VERSION))
	if [ -z "$$(docker images --filter=reference="$$image" --quiet)" ]; then
		make docker-image NAME=tools
	fi
	if [[ ! "$(SH)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		docker run --interactive $(_TTY) --rm \
			--name tools-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep "^AWS_" | grep -v '=$$') \
			--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
			--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PROFILE=$(PROFILE) \
			--volume $(PROJECT_DIR):/project \
			--volume ~/.aws:/root/.aws \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(DIR) \
			$(ARGS) \
			$$image \
				$(CMD)
	else
		docker run --interactive $(_TTY) --rm \
			--name tools-$(BUILD_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7) \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep "^AWS_" | grep -v '=$$') \
			--env-file <(env | grep "^TF_VAR_" | grep -v '=$$') \
			--env-file <(env | grep "^SERV[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^APP[A-Z]*_" | grep -v '=$$') \
			--env-file <(env | grep "^PROJ[A-Z]*_" | grep -v '=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PROFILE=$(PROFILE) \
			--volume $(PROJECT_DIR):/project \
			--volume ~/.aws:/root/.aws \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(DIR) \
			$(ARGS) \
			$$image \
				/bin/sh -c " \
					$(CMD) \
				"
	fi

# ==============================================================================

_docker-get-variables-from-file:
	if [ -f "$(VARS_FILE)" ]; then
		vars=$$(cat $(VARS_FILE) | grep -Eo "^[A-Za-z0-9_]*")
		for var in $$vars; do
			value=$$(echo $$(eval echo "\$$$$var"))
			echo $${var}=$${value}
		done
	fi

# ==============================================================================

.SILENT: \
	_docker-get-variables-from-file \
	docker-get-image-version \
	docker-set-image-version
