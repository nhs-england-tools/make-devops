PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	make docker-build NAME=tools \
		BUILD_OPTS="--build-arg PYTHON_BASE_PACKAGES='$(PYTHON_BASE_PACKAGES)'"

test:
	make docker-test NAME=tools CMD="bash"

push:
	make docker-push NAME=tools

clean:
	make docker-image-clean NAME=tools
