PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	make _generate-ssl-certificate
	make docker-build NAME=nginx

test:
	make docker-test NAME=nginx

push:
	make docker-push NAME=nginx

clean:
	make docker-image-clean NAME=nginx

# ==============================================================================

build-example:
	make docker-build NAME=nginx EXAMPLE=true

test-example:
	make docker-test NAME=nginx EXAMPLE=true

run-example:
	make docker-image-start NAME=nginx EXAMPLE=true \
		ARGS=" \
			--workdir /application \
			--publish 8080:8080 \
			--publish 8443:8443 \
			--attach \
			--rm \
		"

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIB_IMAGE_DIR)/nginx/assets/certificate/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIB_IMAGE_DIR)/nginx/assets/certificate \
			DOMAINS=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
