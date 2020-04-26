PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../automation/init.mk)

# ==============================================================================

build:
	make docker-build NAME=tools

test:
	make docker-test NAME=tools

push:
	make docker-push NAME=tools

clean:
	make docker-image-clean NAME=tools
