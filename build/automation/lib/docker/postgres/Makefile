PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../../init.mk)

# ==============================================================================

build:
	make _generate-ssl-certificate
	make docker-build NAME=postgres FROM_CACHE=$(or $(FROM_CACHE), true)
	rm -f $(DOCKER_LIBRARY_DIR)/nginx/.version

test:
	make \
		_test-sql \
		_test-scripts-mount \
		_test-scripts-image \
		_test-postgres

_test-sql:
	make _test-prerequisites-setup
	make docker-run-postgres \
		CMD='sql "select version();"'
	make _test-prerequisites-teardown

_test-scripts-image:
	make _test-prerequisites-setup
	make docker-run-postgres \
		CMD="scripts /sql"
	make _test-prerequisites-teardown

_test-scripts-mount:
	make _test-prerequisites-setup
	make docker-run-postgres \
		ARGS="--volume $(DOCKER_LIBRARY_DIR)/postgres/assets/sql:/sql" \
		CMD="scripts /sql"
	make _test-prerequisites-teardown

_test-postgres:
	make docker-test NAME=postgres \
		GOSS_OPTS="GOSS_SLEEP=3" \
		ARGS="--env POSTGRES_PASSWORD=postgres" \
		CMD="postgres"

push:
	make docker-push NAME=postgres

clean:
	make docker-image-clean NAME=postgres

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIBRARY_DIR)/postgres/assets/etc/postgresql/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIBRARY_DIR)/postgres/assets/etc/postgresql \
			NAME=certificate
	fi

_test-prerequisites-setup:
	make docker-compose-stop docker-compose-start \
		YML=$(DOCKER_LIBRARY_DIR)/postgres/test/docker-compose.postgres.yml
	sleep 1

_test-prerequisites-teardown:
	make docker-compose-stop \
		YML=$(DOCKER_LIBRARY_DIR)/postgres/test/docker-compose.postgres.yml
