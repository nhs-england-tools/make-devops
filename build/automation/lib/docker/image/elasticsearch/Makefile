PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	make docker-build NAME=elasticsearch FROM_CACHE=$(or $(FROM_CACHE), true)

test:
	make docker-test NAME=elasticsearch \
		GOSS_OPTS="GOSS_SLEEP=20" \
		CMD="elasticsearch"

push:
	make docker-push NAME=elasticsearch

clean:
	make docker-image-clean NAME=elasticsearch
