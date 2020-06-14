PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	make _generate-ssl-certificate
	make docker-build NAME=node

test:
	make docker-test NAME=node CMD="bash"

push:
	make docker-push NAME=node

clean:
	make docker-image-clean NAME=node

# ==============================================================================

build-example:
	make docker-build NAME=node EXAMPLE=true

test-example:
	make docker-test NAME=node EXAMPLE=true

run-example:
	make docker-image-start NAME=node EXAMPLE=true \
		ARGS=" \
			--workdir /application \
			--publish 8080:8080 \
			--publish 8443:8443 \
			--attach \
			--rm \
		"

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIB_IMAGE_DIR)/node/assets/certificate/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIB_IMAGE_DIR)/node/assets/certificate \
			DOMAINS=node.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
