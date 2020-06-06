PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../../init.mk)

DOCKER_PYTHON_VERSION = $(PYTHON_VERSION)-alpine

# ==============================================================================

build:
	make docker-build NAME=python FROM_CACHE=false

test:
	make docker-test NAME=python CMD="bash"

push:
	make docker-push NAME=python

clean:
	make docker-image-clean NAME=python
