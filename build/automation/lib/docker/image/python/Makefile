PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

DOCKER_PYTHON_VERSION = $(PYTHON_VERSION)-alpine

# ==============================================================================

build:
	make docker-build NAME=python

test:
	make docker-test NAME=python CMD="bash"

push:
	make docker-push NAME=python

clean:
	make docker-image-clean NAME=python
