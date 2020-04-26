PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../automation/init.mk)

# ==============================================================================

build:
	make _generate_ssl_certificate
	make docker-build NAME=nginx CACHE_FROM=true

test:
	make docker-test NAME=nginx ARGS=" \
		--env PROJECT_GROUP_SHORT=$(PROJECT_GROUP_SHORT) \
		--env PROJECT_NAME_SHORT=$(PROJECT_NAME_SHORT) \
	"

push:
	make docker-push NAME=nginx

clean:
	make docker-image-clean NAME=nginx

# ==============================================================================

_generate_ssl_certificate:
	if [ ! -f $(DOCKER_DIR)/nginx/assets/certificate/nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_DIR)/nginx/assets/certificate \
			NAME=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT) \
			DOMAINS=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
