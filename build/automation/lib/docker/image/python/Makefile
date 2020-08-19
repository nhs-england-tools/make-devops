PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	[ -n "$(FORCE)" ] && target=docker-build || target=docker-image-pull-or-build
	make $$target NAME=python

test:
	make docker-test NAME=python CMD="bash"

push:
	make docker-push NAME=python

clean:
	make docker-image-clean NAME=python
