PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build: _generate-ssl-certificate
	[ -n "$(FORCE)" ] && target=docker-build || target="docker-image-pull-or-build VERSION=$(DOCKER_LIBRARY_PYTHON_APP_VERSION) LATEST=true"
	make $$target NAME=python-app

test:
	make docker-test NAME=python-app CMD="bash"

push:
	make docker-push NAME=python-app

clean:
	make docker-image-clean NAME=python-app

# ==============================================================================

build-example:
	make docker-build NAME=python-app EXAMPLE=true

test-example:
	make docker-test NAME=python-app EXAMPLE=true \
		GOSS_OPTS="GOSS_SLEEP=3"

run-example:
	make docker-image-start NAME=python-app EXAMPLE=true \
		ARGS=" \
			--workdir /application \
			--publish 8443:8443 \
			--attach \
			--rm \
		"

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIB_IMAGE_DIR)/python-app/assets/certificate/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIB_IMAGE_DIR)/python-app/assets/certificate \
			DOMAINS=python-app.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi
