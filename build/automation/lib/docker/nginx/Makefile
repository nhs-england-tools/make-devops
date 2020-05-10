PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../../init.mk)

# ==============================================================================

build:
	make _generate-ssl-certificate
	make docker-build NAME=nginx FROM_CACHE=$(or $(FROM_CACHE), true)
	rm -f $(DOCKER_LIBRARY_DIR)/nginx/.version

test:
	make docker-test NAME=nginx

push:
	make docker-push NAME=nginx

clean:
	make docker-image-clean NAME=nginx

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIBRARY_DIR)/nginx/assets/certificate/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIBRARY_DIR)/nginx/assets/certificate \
			DOMAINS=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
