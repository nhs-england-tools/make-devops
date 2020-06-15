PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

dependencies:
	cd $(APPLICATION_DIR)
	tar -czf $(DOCKER_DIR)/NAME_TEMPLATE_TO_REPLACE/assets/application.tar.gz *

build:
	make _generate-ssl-certificate
	make docker-build NAME=NAME_TEMPLATE_TO_REPLACE

test:
	make docker-test NAME=NAME_TEMPLATE_TO_REPLACE GOSS_OPTS="GOSS_SLEEP=3"

run:
	make docker-image-start NAME=NAME_TEMPLATE_TO_REPLACE \
		DIR="$(PROJECT_DIR)/application" \
		ARGS=" \
			--publish 8443:8443 \
			--attach \
			--rm \
		"

push:
	make docker-push NAME=NAME_TEMPLATE_TO_REPLACE

clean:
	make docker-image-clean NAME=NAME_TEMPLATE_TO_REPLACE

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_DIR)/NAME_TEMPLATE_TO_REPLACE/assets/certificate/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_DIR)/NAME_TEMPLATE_TO_REPLACE/assets/certificate \
			DOMAINS=NAME_TEMPLATE_TO_REPLACE.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
