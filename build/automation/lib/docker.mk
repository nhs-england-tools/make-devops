DOCKER_COMPOSE_YML = $(DOCKER_DIR)/docker-compose.yml
DOCKER_DIR = $(abspath $(PROJECT_DIR)/build/docker)
DOCKER_DIR_REL = $(shell echo $(DOCKER_DIR) | sed "s;$(PROJECT_DIR);;g")
DOCKER_LIB_DIR = $(LIB_DIR)/docker
DOCKER_LIB_IMAGE_DIR = $(LIB_DIR)/docker/image
DOCKER_NETWORK = $(PROJECT_GROUP_SHORT)/$(PROJECT_NAME_SHORT)/$(BUILD_ID)
DOCKER_REGISTRY = $(AWS_ECR)/$(PROJECT_GROUP_SHORT)/$(PROJECT_NAME_SHORT)
DOCKER_LIBRARY_REGISTRY = nhsd

DOCKER_ALPINE_VERSION = 3.12.0
DOCKER_COMPOSER_VERSION = 1.10.10
DOCKER_DOTNET_VERSION = 3.1.401
DOCKER_ELASTICSEARCH_VERSION = 7.9.0
DOCKER_GRADLE_VERSION = 6.6.1-jdk$(JAVA_VERSION)
DOCKER_LOCALSTACK_VERSION = $(LOCALSTACK_VERSION)
DOCKER_MAVEN_VERSION = 3.6.3-openjdk-$(JAVA_VERSION)-slim
DOCKER_NGINX_VERSION = 1.19.2-alpine
DOCKER_NODE_VERSION = 14.9.0-alpine
DOCKER_OPENJDK_VERSION = $(JAVA_VERSION)-alpine
DOCKER_POSTGRES_VERSION = $(POSTGRES_VERSION)-alpine
DOCKER_POSTMAN_NEWMAN_VERSION = $(POSTMAN_NEWMAN_VERSION)-alpine
DOCKER_PULUMI_VERSION = v2.9.1
DOCKER_PYTHON_VERSION = $(PYTHON_VERSION)-alpine
DOCKER_TERRAFORM_VERSION = $(TERRAFORM_VERSION)
DOCKER_WIREMOCK_VERSION = $(WIREMOCK_VERSION)-alpine

DOCKER_LIBRARY_ELASTICSEARCH_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/elasticsearch/VERSION 2> /dev/null)
DOCKER_LIBRARY_NGINX_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/nginx/VERSION 2> /dev/null)
DOCKER_LIBRARY_NODE_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/node/VERSION 2> /dev/null)
DOCKER_LIBRARY_POSTGRES_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/postgres/VERSION 2> /dev/null)
DOCKER_LIBRARY_PYTHON_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/python/VERSION 2> /dev/null)
DOCKER_LIBRARY_PYTHON_APP_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/python-app/VERSION 2> /dev/null)
DOCKER_LIBRARY_TOOLS_VERSION = $(shell cat $(DOCKER_LIB_IMAGE_DIR)/tools/VERSION 2> /dev/null)

COMPOSE_HTTP_TIMEOUT := $(or $(COMPOSE_HTTP_TIMEOUT), 6000)
DOCKER_CLIENT_TIMEOUT := $(or $(DOCKER_CLIENT_TIMEOUT), 6000)

# ==============================================================================

docker-create-from-template: ### Create Docker image from template - mandatory: NAME,TEMPLATE=[library template image name]
	mkdir -p $(DOCKER_DIR)
	if [ ! -f $(DOCKER_DIR)/docker-compose.yml ]; then
		cp -rfv \
			$(PROJECT_DIR)/build/automation/lib/project/template/build/docker/docker-compose.yml \
			$(DOCKER_DIR)
	fi
	rm -rf $(DOCKER_DIR)/$(NAME)
	cp -rfv $(DOCKER_LIB_DIR)/template/$(TEMPLATE) $(DOCKER_DIR)/$(NAME)
	find $(DOCKER_DIR)/$(NAME) -type f -name '.gitkeep' -print | xargs rm -fv
	# Replace template values
	export SUFFIX=_TEMPLATE_TO_REPLACE
	export VERSION=$$(make docker-image-get-version NAME=$(TEMPLATE))
	make -s file-replace-variables-in-dir DIR=$(DOCKER_DIR)/$(NAME)
	make -s file-replace-variables FILE=$(DOCKER_DIR)/docker-compose.yml
	make -s file-replace-variables FILE=Makefile

# ==============================================================================

docker-config: ### Configure Docker networking
	docker network create $(DOCKER_NETWORK) 2> /dev/null ||:

docker-build docker-image: ### Build Docker image - mandatory: NAME; optional: VERSION,FROM_CACHE=true,BUILD_OPTS=[build options],EXAMPLE=true
	reg=$$(make _docker-get-reg)
	# Try to execute `make build` from the image directory
	if [ -d $(DOCKER_LIB_IMAGE_DIR)/$(NAME) ] && [ -z "$(__DOCKER_BUILD)" ]; then
		cd $(DOCKER_LIB_IMAGE_DIR)/$(NAME)
		make build __DOCKER_BUILD=true DOCKER_REGISTRY=$(DOCKER_LIBRARY_REGISTRY)
		exit
	elif [ -d $(DOCKER_CUSTOM_DIR)/$(NAME) ] && [ -z "$(__DOCKER_BUILD)" ]; then
		cd $(DOCKER_CUSTOM_DIR)/$(NAME)
		make build __DOCKER_BUILD=true && exit || cd $(PROJECT_DIR)
	elif [ -d $(DOCKER_DIR)/$(NAME) ] && [ -z "$(__DOCKER_BUILD)" ]; then
		cd $(DOCKER_DIR)/$(NAME)
		make build __DOCKER_BUILD=true && exit || cd $(PROJECT_DIR)
	fi
	# Dockerfile
	make NAME=$(NAME) \
		docker-create-dockerfile FILE=Dockerfile$(shell [ -n "$(EXAMPLE)" ] && echo .example) \
		docker-image-set-version VERSION=$(VERSION)
	# Cache
	cache_from=
	if [[ "$(FROM_CACHE)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		make docker-pull NAME=$(NAME) VERSION=latest
		cache_from="--cache-from $$reg/$(NAME):latest"
	fi
	# Build
	dir=$$(make _docker-get-dir)
	docker build --rm \
		--build-arg IMAGE=$$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example) \
		--build-arg VERSION=$$(make docker-image-get-version) \
		--build-arg BUILD_ID=$(BUILD_ID) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg BUILD_REPO=$(BUILD_REPO) \
		--build-arg BUILD_BRANCH=$(BUILD_BRANCH) \
		--build-arg BUILD_COMMIT_HASH=$(BUILD_COMMIT_HASH) \
		--build-arg BUILD_COMMIT_DATE=$(BUILD_COMMIT_DATE) \
		$(BUILD_OPTS) $$cache_from \
		--file $$dir/Dockerfile.effective \
		--tag $$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):$$(make docker-image-get-version) \
		$$dir
	# Tag
	docker tag \
		$$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):$$(make docker-image-get-version) \
		$$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):latest
	docker rmi --force $$(docker images | grep "<none>" | awk '{ print $$3 }') 2> /dev/null ||:
	make docker-image-keep-latest-only NAME=$(NAME)
	docker image inspect $$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):latest --format='{{.Size}}'

docker-test: ### Test image - mandatory: NAME; optional: ARGS,CMD,GOSS_OPTS,EXAMPLE=true
	dir=$$(make _docker-get-dir)
	reg=$$(make _docker-get-reg)
	GOSS_FILES_PATH=$$dir/test \
	GOSS_FILE=$(shell [ -z "$(EXAMPLE)" ] && echo goss.yaml || echo goss-example.yaml) \
	CONTAINER_LOG_OUTPUT=$(TMP_DIR)/container-$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example)-$(BUILD_COMMIT_HASH)-$(BUILD_ID).log \
	$(GOSS_OPTS) \
	dgoss run --interactive $(_TTY) \
		$(ARGS) \
		$$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):latest \
		$(CMD)

docker-login: ### Log into the Docker registry - optional: DOCKER_USERNAME,DOCKER_PASSWORD
	if [ -n "$(DOCKER_USERNAME)" ] && [ -n "$(DOCKER_PASSWORD)" ]; then
		make _docker-get-login-password | docker login --username "$(DOCKER_USERNAME)" --password-stdin
	else
		make aws-ecr-get-login-password | docker login --username AWS --password-stdin $(AWS_ECR)
	fi

docker-create-repository: ### Create Docker repository to store an image - mandatory: NAME
	make aws-ecr-create-repository NAME=$(NAME)

docker-push: ### Push Docker image - mandatory: NAME; optional: VERSION|TAG
	make docker-login
	reg=$$(make _docker-get-reg)
	if [ -n "$(or $(VERSION), $(TAG))" ]; then
		docker push $$reg/$(NAME):$(or $(VERSION), $(TAG))
	else
		docker push $$reg/$(NAME):$$(make docker-image-get-version)
	fi
	docker push $$reg/$(NAME):latest 2> /dev/null ||:

docker-pull: ### Pull Docker image - mandatory: NAME,DIGEST|VERSION|TAG
	[ $$(make _docker-is-lib-image) == false ] && make docker-login
	reg=$$(make _docker-get-reg)
	if [ -n "$(DIGEST)" ]; then
		docker pull $$reg/$(NAME)@$(DIGEST) ||:
	else
		docker pull $$reg/$(NAME):$(or $(VERSION), $(TAG)) ||:
	fi

docker-tag: ### Tag latest or provide arguments - mandatory: NAME,VERSION|TAG|[SOURCE,TARGET]|[DIGEST,VERSION|TAG]
	reg=$$(make _docker-get-reg)
	if [ -n "$(DIGEST)" ] && [ -n "$(TAG)" ]; then
		docker tag \
			$$reg/$(NAME)@$(DIGEST) \
			$$reg/$(NAME):$(or $(VERSION), $(TAG))
	elif [ -n "$(SOURCE)" ] && [ -n "$(TARGET)" ]; then
		docker tag \
			$$reg/$(NAME):$(SOURCE) \
			$$reg/$(NAME):$(TARGET)
	elif [ -n "$(or $(VERSION), $(TAG))" ]; then
		docker tag \
			$$reg/$(NAME):latest \
			$$reg/$(NAME):$(or $(VERSION), $(TAG))
	fi

docker-rename: ### Rename Docker image - mandatory: NAME,AS
	reg=$$(make _docker-get-reg)
	docker tag \
		$$reg/$(NAME):$$(make docker-image-get-version) \
		$$reg/$(AS):$$(make docker-image-get-version)
	docker tag \
		$$reg/$(NAME):latest \
		$$reg/$(AS):latest
	make docker-image-keep-latest-only NAME=$(AS)

docker-clean: ### Clean Docker files
	find $(DOCKER_DIR) -type f -name '.version' -print0 | xargs -0 rm -v 2> /dev/null ||:
	find $(DOCKER_DIR) -type f -name 'Dockerfile.effective' -print0 | xargs -0 rm -v 2> /dev/null ||:
	find $(DOCKER_LIB_IMAGE_DIR) -type f -name '.version' -print0 | xargs -0 rm -v 2> /dev/null ||:
	find $(DOCKER_LIB_IMAGE_DIR) -type f -name 'Dockerfile.effective' -print0 | xargs -0 rm -v 2> /dev/null ||:

docker-prune: docker-clean ### Clean Docker resources - optional: ALL=true
	docker rmi --force $$(docker images | grep $(DOCKER_REGISTRY) | awk '{ print $$3 }') 2> /dev/null ||:
	docker rmi --force $$(docker images | grep $(DOCKER_LIBRARY_REGISTRY) | awk '{ print $$3 }') 2> /dev/null ||:
	docker network rm $(DOCKER_NETWORK) 2> /dev/null ||:
	[[ "$(ALL)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]] && docker system prune --volumes --all --force ||:

# ==============================================================================

docker-create-dockerfile: ### Create effective Dockerfile - mandatory: NAME; optional FILE=[Dockerfile name, defaults to Dockerfile]
	dir=$$(pwd)
	cd $$(make _docker-get-dir)
	cat $(or $(FILE), Dockerfile) $(DOCKER_LIB_DIR)/image/Dockerfile.metadata > Dockerfile.effective
	sed -i " \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/elasticsearch:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/elasticsearch:${DOCKER_LIBRARY_ELASTICSEARCH_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/nginx:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/nginx:${DOCKER_LIBRARY_NGINX_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/node:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/node:${DOCKER_LIBRARY_NODE_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/postgres:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/postgres:${DOCKER_LIBRARY_POSTGRES_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/python:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/python:${DOCKER_LIBRARY_PYTHON_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/python-app:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/python-app:${DOCKER_LIBRARY_PYTHON_APP_VERSION}#g; \
		s#FROM $(DOCKER_LIBRARY_REGISTRY)/tools:latest#FROM $(DOCKER_LIBRARY_REGISTRY)/tools:${DOCKER_LIBRARY_TOOLS_VERSION}#g; \
		s#FROM alpine:latest#FROM alpine:${DOCKER_ALPINE_VERSION}#g; \
		s#FROM bitnami/elasticsearch:latest#FROM bitnami/elasticsearch:${DOCKER_ELASTICSEARCH_VERSION}#g; \
		s#FROM gradle:latest#FROM gradle:${DOCKER_GRADLE_VERSION}#g; \
		s#FROM maven:latest#FROM maven:${DOCKER_MAVEN_VERSION}#g; \
		s#FROM mcr.microsoft.com/dotnet/core/sdk:latest#FROM mcr.microsoft.com/dotnet/core/sdk:${DOCKER_DOTNET_VERSION}#g; \
		s#FROM nginx:latest#FROM nginx:${DOCKER_NGINX_VERSION}#g; \
		s#FROM node:latest#FROM node:${DOCKER_NODE_VERSION}#g; \
		s#FROM openjdk:latest#FROM openjdk:${DOCKER_OPENJDK_VERSION}#g; \
		s#FROM postgres:latest#FROM postgres:${DOCKER_POSTGRES_VERSION}#g; \
		s#FROM postman/newman:latest#FROM postman/newman:${DOCKER_POSTMAN_NEWMAN_VERSION}#g; \
		s#FROM python:latest#FROM python:${DOCKER_PYTHON_VERSION}#g; \
		s#FROM rodolpheche/wiremock:latest#FROM rodolpheche/wiremock:${DOCKER_WIREMOCK_VERSION}#g; \
	" Dockerfile.effective
	cd $$dir

docker-image-get-version: ### Get effective Docker image version - mandatory: NAME
	dir=$$(make _docker-get-dir)
	cat $$dir/.version 2> /dev/null || cat $$dir/VERSION 2> /dev/null || echo unknown

docker-image-set-version: ### Set effective Docker image version - mandatory: NAME; optional: VERSION
	if [ -d $(DOCKER_LIB_IMAGE_DIR)/$(NAME) ] && [ -z "$(DOCKER_CUSTOM_DIR)" ]; then
		rm -f $(DOCKER_LIB_IMAGE_DIR)/$(NAME)/.version
		exit
	fi
	dir=$$(make _docker-get-dir)
	if [ -n "$(VERSION)" ]; then
		echo $(VERSION) > $$dir/.version
	else
		echo $$(cat $$dir/VERSION) | \
			sed "s/YYYY/$$(date --date=$(BUILD_DATE) -u +"%Y")/g" | \
			sed "s/mm/$$(date --date=$(BUILD_DATE) -u +"%m")/g" | \
			sed "s/dd/$$(date --date=$(BUILD_DATE) -u +"%d")/g" | \
			sed "s/HH/$$(date --date=$(BUILD_DATE) -u +"%H")/g" | \
			sed "s/MM/$$(date --date=$(BUILD_DATE) -u +"%M")/g" | \
			sed "s/ss/$$(date --date=$(BUILD_DATE) -u +"%S")/g" | \
			sed "s/hash/$$(git rev-parse --short HEAD)/g" \
		> $$dir/.version
	fi

# ==============================================================================

docker-image-pull-or-build: ### Pull or build image - mandatory: NAME; optional VERSION|TAG=[defaults to 'latest'],LATEST=true
	version=$(or $(or $(VERSION), $(TAG)), latest)
	image=$(DOCKER_LIBRARY_REGISTRY)/$(NAME):$$version
	if [ -z "$$(docker images --filter=reference="$$image" --quiet)" ]; then
		make docker-pull NAME=$(NAME) VERSION=$$version ||:
	fi
	if [ -z "$$(docker images --filter=reference="$$image" --quiet)" ]; then
			make docker-build NAME=$(NAME) || ( \
				echo "ERROR: No image $$image found"; \
				exit 1 \
			)
	fi
	if [ -n "$$(docker images --filter=reference="$$image" --quiet)" ]; then
		[[ "$(LATEST)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]] && \
			make docker-tag NAME=$(NAME) SOURCE=$$version TARGET=latest ||:
	fi

docker-image-keep-latest-only: ### Remove other images than latest - mandatory: NAME
	reg=$$(make _docker-get-reg)
	docker rmi --force $$( \
		docker images --filter=reference="$$reg/$(NAME):*" --quiet | \
			grep -v $$(docker images --filter=reference="$$reg/$(NAME):latest" --quiet) \
	) 2> /dev/null ||:

docker-image-start: ### Start container - mandatory: NAME; optional: CMD,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],EXAMPLE=true
	reg=$$(make _docker-get-reg)
	docker run --interactive $(_TTY) $$(echo $(ARGS) | grep -- "--attach" > /dev/null 2>&1 && : || echo "--detach") \
		--name $(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example)-$(BUILD_COMMIT_HASH)-$(BUILD_ID) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$$(echo $(ARGS) | sed -e "s/--attach//g") \
		$$reg/$(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example):latest \
		$(CMD)

docker-image-stop: ### Stop container - mandatory: NAME; optional: EXAMPLE=true
	docker stop $(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example)-$(BUILD_COMMIT_HASH)-$(BUILD_ID) 2> /dev/null ||:
	docker rm --force --volumes $(NAME)-$(BUILD_COMMIT_HASH)-$(BUILD_ID) 2> /dev/null ||:

docker-image-log: ### Log output of a container - mandatory: NAME; optional: EXAMPLE=true
	docker logs --follow $(NAME)$(shell [ -n "$(EXAMPLE)" ] && echo -example)-$(BUILD_COMMIT_HASH)-$(BUILD_ID)

docker-image-bash: ### Bash into a container - mandatory: NAME
	docker exec --interactive $(_TTY) --user root \
		$(NAME)-$(BUILD_COMMIT_HASH)-$(BUILD_ID) \
		bash --login || \
	docker exec --interactive $(_TTY) --user root \
		$(NAME)-$(BUILD_COMMIT_HASH)-$(BUILD_ID) \
		sh --login ||:

docker-image-clean: docker-image-stop ### Clean up container and image resources - mandatory: NAME
	dir=$$(make _docker-get-dir)
	reg=$$(make _docker-get-reg)
	docker rmi --force $$(docker images --filter=reference="$$reg/$(NAME)-example:*" --quiet) 2> /dev/null ||:
	docker rmi --force $$(docker images --filter=reference="$$reg/$(NAME):*" --quiet) 2> /dev/null ||:
	rm -fv \
		$$dir/.version \
		$$dir/$(NAME)-*-image.tar.gz \
		$$dir/Dockerfile.effective

docker-image-save: ### Save image as a flat file - mandatory: NAME; optional: VERSION|TAG
	dir=$$(make _docker-get-dir)
	reg=$$(make _docker-get-reg)
	version=$(or $(VERSION), $(TAG))
	if [ -z "$$version" ]; then
		version=$$(make docker-image-get-version)
	fi
	docker save $$reg/$(NAME):$$version | gzip > $$dir/$(NAME)-$$version-image.tar.gz

docker-image-load: ### Load image from a flat file - mandatory: NAME; optional: VERSION|TAG
	dir=$$(make _docker-get-dir)
	version=$(or $(VERSION), $(TAG))
	if [ -z "$$version" ]; then
		version=$$(make docker-image-get-version)
	fi
	gunzip -c $$dir/$(NAME)-$$version-image.tar.gz | docker load

# ==============================================================================

docker-run: ### Run specified image - mandatory: IMAGE; optional: CMD,SH=true,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo $$(echo '$(IMAGE)' | md5sum | cut -c1-7)-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	if [[ ! "$(SH)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--volume $(PROJECT_DIR):/project \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$(IMAGE) \
				$(CMD)
	else
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--volume $(PROJECT_DIR):/project \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$(IMAGE) \
				/bin/sh -c " \
					$(CMD) \
				"
	fi

docker-run-composer: ### Run composer container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.composer
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo composer:$(DOCKER_COMPOSER_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo composer-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--volume $(TMP_DIR)/.composer:/tmp \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-dotnet: ### Run dotnet container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo mcr.microsoft.com/dotnet/core/sdk:$(DOCKER_DOTNET_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo dotnet-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			dotnet $(CMD)

docker-run-gradle: ### Run gradle container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.gradle
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo gradle:$(DOCKER_GRADLE_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo gradle-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env GRADLE_USER_HOME=/home/gradle/.gradle \
		--volume $(PROJECT_DIR):/project \
		--volume $(TMP_DIR)/.gradle:/home/gradle/.gradle \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-mvn: ### Run maven container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.m2
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo maven:$(DOCKER_MAVEN_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo mvn-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--env MAVEN_CONFIG=/var/maven/.m2 \
		--volume $(PROJECT_DIR):/project \
		--volume $(TMP_DIR)/.m2:/var/maven/.m2 \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			/bin/sh -c " \
				mvn -Duser.home=/var/maven $(CMD) \
			"

docker-run-node: ### Run node container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.cache
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo node:$(DOCKER_NODE_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo node-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--volume $(TMP_DIR)/.cache:/home/default/.cache \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			/bin/sh -c " \
				groupadd default -g $$(id -g) 2> /dev/null ||: && \
				useradd default -u $$(id -u) -g $$(id -g) 2> /dev/null ||: && \
				chown $$(id -u):$$(id -g) /home/\$$(id -nu $$(id -u)) ||: && \
				su \$$(id -nu $$(id -u)) -c 'cd /project/$(DIR); $(CMD)' \
			"

docker-run-postman: ### Run postman (newman) container - mandatory: DIR,CMD
	make docker-config > /dev/null 2>&1
	make docker-run IMAGE=postman/newman:$(DOCKER_POSTMAN_NEWMAN_VERSION) \
		ARGS="--volume $(DIR):/etc/newman" \
		DIR="$(DIR)" \
		CMD="$(CMD)"

docker-run-pulumi: ### Run pulumi container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo pulumi/pulumi:$(DOCKER_PULUMI_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo pulumi-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^TF_VAR_" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^PULUMI_" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		--entrypoint /bin/bash \
		$(ARGS) \
		$$image \
			-c "$(CMD)"

docker-run-python: ### Run python container - mandatory: CMD; optional: SH=true,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.python/pip/{cache,packages}
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo python:$(DOCKER_PYTHON_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo python-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	if [[ ! "$(SH)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--volume $(PROJECT_DIR):/project \
			--volume $(TMP_DIR)/.python/pip/cache:/tmp/.cache/pip \
			--volume $(TMP_DIR)/.python/pip/packages:/tmp/.packages \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$$image \
				$(CMD)
	else
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--volume $(PROJECT_DIR):/project \
			--volume $(TMP_DIR)/.python/pip/cache:/tmp/.cache/pip \
			--volume $(TMP_DIR)/.python/pip/packages:/tmp/.packages \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$$image \
				/bin/sh -c " \
					$(CMD) \
				"
	fi

docker-run-terraform: ### Run terraform container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo hashicorp/terraform:$(DOCKER_TERRAFORM_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo terraform-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^TF_VAR_" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			$(CMD)

# ==============================================================================

docker-run-postgres: ### Run postgres container - mandatory: CMD; optional: DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo $(DOCKER_LIBRARY_REGISTRY)/postgres:$(DOCKER_LIBRARY_POSTGRES_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo postgres-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	make docker-image-pull-or-build NAME=postgres VERSION=$(DOCKER_LIBRARY_POSTGRES_VERSION) >&2
	docker run --interactive $(_TTY) --rm \
		--name $$container \
		--user $$(id -u):$$(id -g) \
		--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
		--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
		--volume $(PROJECT_DIR):/project \
		--network $(DOCKER_NETWORK) \
		--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
		$(ARGS) \
		$$image \
			$(CMD)

docker-run-tools: ### Run tools (Python) container - mandatory: CMD; optional: SH=true,DIR,ARGS=[Docker args],VARS_FILE=[Makefile vars file],IMAGE=[image name],CONTAINER=[container name]
	make docker-config > /dev/null 2>&1
	mkdir -p $(TMP_DIR)/.python/pip/{cache,packages}
	mkdir -p $(HOME)/.aws
	image=$$([ -n "$(IMAGE)" ] && echo $(IMAGE) || echo $(DOCKER_LIBRARY_REGISTRY)/tools:$(DOCKER_LIBRARY_TOOLS_VERSION))
	container=$$([ -n "$(CONTAINER)" ] && echo $(CONTAINER) || echo tools-$(BUILD_COMMIT_HASH)-$(BUILD_ID)-$$(echo '$(CMD)$(DIR)' | md5sum | cut -c1-7))
	make docker-image-pull-or-build NAME=tools VERSION=$(DOCKER_LIBRARY_TOOLS_VERSION) >&2
	if [[ ! "$(SH)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]]; then
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env HOME=/tmp \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--volume $(PROJECT_DIR):/project \
			--volume $(TMP_DIR)/.python/pip/cache:/tmp/.cache/pip \
			--volume $(TMP_DIR)/.python/pip/packages:/tmp/.packages \
			--volume $(HOME)/.aws:/tmp/.aws \
			--volume $(HOME)/bin:/tmp/bin \
			--volume $(HOME)/etc:/tmp/etc \
			--volume $(HOME)/usr:/tmp/usr \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$$image \
				$(CMD)
	else
		docker run --interactive $(_TTY) --rm \
			--name $$container \
			--user $$(id -u):$$(id -g) \
			--env-file <(env | grep -Ei "^(AWS|TX|TEXAS)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(DB|DATABASE|APP|APPLICATION|UI|API|SERVER|HOST|URL)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(env | grep -Ei "^(PROFILE|BUILD|PROGRAMME|SERVICE|PROJECT)" | sed -e 's/[[:space:]]*$$//' | grep -Ev '[A-Za-z0-9_]+=$$') \
			--env-file <(make _docker-get-variables-from-file VARS_FILE=$(VARS_FILE)) \
			--env HOME=/tmp \
			--env PIP_TARGET=/tmp/.packages \
			--env PYTHONPATH=/tmp/.packages \
			--env XDG_CACHE_HOME=/tmp/.cache \
			--volume $(PROJECT_DIR):/project \
			--volume $(TMP_DIR)/.python/pip/cache:/tmp/.cache/pip \
			--volume $(TMP_DIR)/.python/pip/packages:/tmp/.packages \
			--volume $(HOME)/.aws:/tmp/.aws \
			--volume $(HOME)/bin:/tmp/bin \
			--volume $(HOME)/etc:/tmp/etc \
			--volume $(HOME)/usr:/tmp/usr \
			--network $(DOCKER_NETWORK) \
			--workdir /project/$(shell echo $(abspath $(DIR)) | sed "s;$(PROJECT_DIR);;g") \
			$(ARGS) \
			$$image \
				/bin/sh -c " \
					$(CMD) \
				"
	fi

# ==============================================================================

docker-compose-start: ### Start Docker Compose - optional: YML=[docker-compose.yml, defaults to $(DOCKER_COMPOSE_YML)]
	make docker-config
	yml=$$(make _docker-get-docker-compose-yml YML=$(YML))
	docker-compose --file $$yml \
		up --no-build --detach

docker-compose-start-single-service: ### Start Docker Compose - mandatory: NAME=[service name]; optional: YML=[docker-compose.yml, defaults to $(DOCKER_COMPOSE_YML)]
	make docker-config
	yml=$$(make _docker-get-docker-compose-yml YML=$(YML))
	name=$$([ "$(BUILD_ID)" != 0 ] && echo $(NAME)-$(BUILD_ID) || echo $(NAME))
	docker-compose --file $$yml \
		up --no-build --detach $$name

docker-compose-stop: ### Stop Docker Compose - optional: YML=[docker-compose.yml, defaults to $(DOCKER_COMPOSE_YML)],ALL=true
	make docker-config
	yml=$$(make _docker-get-docker-compose-yml YML=$(YML))
	docker-compose --file $$yml \
		rm \
		--stop \
		--force
	docker rm --force --volumes $$(docker ps --all --filter "name=.*$(BUILD_ID).*" --quiet) 2> /dev/null ||:
	[[ "$(ALL)" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$$ ]] && docker rm --force --volumes $$(docker ps --all --quiet) 2> /dev/null ||:

docker-compose-log: ### Log Docker Compose output - optional: DO_NOT_FOLLOW=true,YML=[docker-compose.yml, defaults to $(DOCKER_COMPOSE_YML)]
	yml=$$(make _docker-get-docker-compose-yml YML=$(YML))
	docker-compose --file $$yml \
		logs $$(echo $(DO_NOT_FOLLOW) | grep -E 'true|yes|y|on|1|TRUE|YES|Y|ON' > /dev/null 2>&1 && : || echo "--follow")

# ==============================================================================

_docker-get-dir:
	if [ -n "$(DOCKER_CUSTOM_DIR)" ] && [ -d $(DOCKER_CUSTOM_DIR)/$(NAME) ]; then
		echo $(DOCKER_CUSTOM_DIR)/$(NAME)
	elif [ -d $(DOCKER_LIB_IMAGE_DIR)/$(NAME) ]; then
		echo $(DOCKER_LIB_IMAGE_DIR)/$(NAME)
	else
		echo $(DOCKER_DIR)/$(NAME)
	fi

_docker-get-reg:
	if [ -n "$(NAME)" ] && (([ -n "$(DOCKER_CUSTOM_DIR)" ] && [ -d $(DOCKER_CUSTOM_DIR)/$(NAME) ]) || [ -d $(DOCKER_LIB_IMAGE_DIR)/$(NAME) ]); then
		echo $(DOCKER_LIBRARY_REGISTRY)
	else
		echo $(DOCKER_REGISTRY)
	fi

_docker-get-variables-from-file:
	if [ -f "$(VARS_FILE)" ]; then
		vars=$$(cat $(VARS_FILE) | grep -Eo "^[A-Za-z0-9_]*")
		for var in $$vars; do
			value=$$(echo $$(eval echo "\$$$$var"))
			echo $${var}=$${value}
		done
	fi

_docker-get-login-password:
	echo $(DOCKER_PASSWORD)

_docker-get-docker-compose-yml:
	yml=$(or $(YML), $(DOCKER_COMPOSE_YML))
	if [ "$(BUILD_ID)" != 0 ]; then
		make -s docker-run-tools ARGS="--env BUILD_ID=$(BUILD_ID)" CMD=" \
			$(BIN_DIR_REL)/docker-compose-processor.py \
				$$(echo $$yml | sed 's;//;/;g' | sed "s;$(PROJECT_DIR);;g") \
				$(TMP_DIR_REL)/docker-compose-$(BUILD_ID).yml \
		"
		yml=$(TMP_DIR)/docker-compose-$(BUILD_ID).yml
	fi
	echo $$yml

_docker-is-lib-image:
	([ -n "$(NAME)" ] && [ -d $(DOCKER_LIB_IMAGE_DIR)/$(NAME) ]) && echo true || echo false

# ==============================================================================

docker-image-get-digest: ### Get image digest by matching tag pattern - mandatory: NAME=[image name],VERSION|TAG=[string to match version/tag of an image]
	[ $$(make _docker-is-lib-image NAME=$(NAME)) == false ] && make docker-login > /dev/null 2>&1
	make aws-ecr-get-image-digest \
		REPO=$$(make _docker-get-reg)/$(NAME) \
		TAG=$(or $(VERSION), $(TAG))

docker-image-find-and-tag-as: ### Find image based on commit and tag it - mandatory: TAG,IMAGE=[image name]; optional: COMMIT=[git commit hash, defaults to HEAD]
	commit=$(or $(COMMIT), master)
	hash=$$(make git-commit-get-hash COMMIT=$$commit)
	digest=$$(make docker-image-get-digest NAME=$(IMAGE) TAG=$$hash)
	make docker-pull NAME=$(IMAGE) DIGEST=$$digest
	make docker-tag NAME=$(IMAGE) DIGEST=$$digest TAG=$(TAG)
	make docker-push NAME=$(IMAGE) TAG=$(TAG)

# ==============================================================================

.SILENT: \
	_docker-get-dir \
	_docker-get-docker-compose-yml \
	_docker-get-login-password \
	_docker-get-reg \
	_docker-get-variables-from-file \
	_docker-is-lib-image \
	docker-image-get-digest \
	docker-image-get-version \
	docker-image-set-version
