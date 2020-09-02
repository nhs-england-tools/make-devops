PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	[ -n "$(FORCE)" ] && target=docker-build || target="docker-image-pull-or-build VERSION=$(DOCKER_LIBRARY_ELASTICSEARCH_VERSION) LATEST=true"
	make $$target NAME=elasticsearch FROM_CACHE=$(or $(FROM_CACHE), true)

test:
	make docker-test NAME=elasticsearch \
		GOSS_OPTS="GOSS_SLEEP=20" \
		CMD="elasticsearch"

push:
	make docker-push NAME=elasticsearch

clean:
	make docker-image-clean NAME=elasticsearch
