PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../automation/init.mk)

# ==============================================================================

build:
	make docker-build NAME=postgres

test:
	make \
		_test-sql \
		_test-scripts \
		_test-postgres

_test-sql:
	make _test-prerequisites-setup
	make docker-run-postgres \
		CMD='sql "select version();"'
	make _test-prerequisites-teardown

_test-scripts:
	make _test-prerequisites-setup
	make docker-run-postgres \
		ARGS="--volume $(DOCKER_DIR)/postgres/assets/sql:/sql" \
		CMD="scripts /sql"
	make _test-prerequisites-teardown

_test-postgres:
	make docker-test NAME=postgres \
		GOSS_OPTS="GOSS_SLEEP=1" \
		ARGS="--env POSTGRES_PASSWORD=postgres" \
		CMD="postgres"

clean:
	make docker-image-clean NAME=postgres
	find $(DOCKER_DIR)/postgres/assets/sql -mindepth 1 -maxdepth 1 -not -name '.gitignore' -print | xargs rm -rfv

# ==============================================================================

_test-prerequisites-setup:
	make _postgres_script
	make docker-compose-stop docker-compose-start \
		YML=$(DOCKER_DIR)/postgres/test/docker-compose.postgres.yml
	sleep 1

_test-prerequisites-teardown:
	make docker-compose-stop \
		YML=$(DOCKER_DIR)/postgres/test/docker-compose.postgres.yml

_POSTGRES_SCRIPT := $(DOCKER_DIR)/postgres/assets/sql/00-version.sql
_postgres_script:
	echo "select version();" > $(_POSTGRES_SCRIPT)
