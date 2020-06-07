PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

build:
	make _generate-ssl-certificate
	make docker-build NAME=postgres FROM_CACHE=$(or $(FROM_CACHE), true)

test:
	make \
		_test-sql \
		_test-scripts \
		_test-postgres

_test-sql:
	make _test-prerequisites-setup
	make docker-run-postgres \
		ARGS=" \
			--env DB_HOST=postgres.$(PROJECT_NAME_SHORT).local \
			--env WAIT_FOR=postgres.$(PROJECT_NAME_SHORT).local:5432 \
		" \
		CMD='sql "select version();"'
	make _test-prerequisites-teardown

_test-scripts:
	make _test-prerequisites-setup
	make docker-run-postgres \
		ARGS=" \
			--env DB_HOST=postgres.$(PROJECT_NAME_SHORT).local \
			--env WAIT_FOR=postgres.$(PROJECT_NAME_SHORT).local:5432 \
			--volume $(DOCKER_LIB_IMAGE_DIR)/postgres/assets/data:/data \
		" \
		CMD="scripts"
	make _test-prerequisites-teardown

_test-postgres:
	make docker-test NAME=postgres \
		GOSS_OPTS="GOSS_SLEEP=3" \
		ARGS=" \
			--env DB_NAME=test \
			--env DB_USERNAME=test \
			--env DB_PASSWORD=test \
		" \
		CMD="postgres"

push:
	make docker-push NAME=postgres

clean:
	make docker-image-clean NAME=postgres

# ==============================================================================

_generate-ssl-certificate:
	if [ ! -f $(DOCKER_LIB_IMAGE_DIR)/postgres/assets/etc/postgresql/certificate.pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_LIB_IMAGE_DIR)/postgres/assets/etc/postgresql \
			NAME=certificate
	fi

_test-prerequisites-setup:
	make _TEST_POSTGRES_SQL_FILE
	make \
		docker-compose-stop ALL=true \
		docker-compose-start \
		YML=$(DOCKER_LIB_IMAGE_DIR)/postgres/test/docker-compose.postgres.yml

_test-prerequisites-teardown:
	make \
		docker-compose-stop ALL=true \
		YML=$(DOCKER_LIB_IMAGE_DIR)/postgres/test/docker-compose.postgres.yml
	rm -rf $(_TEST_POSTGRES_SQL_FILE)*

_TEST_POSTGRES_SQL_FILE := $(DOCKER_LIB_IMAGE_DIR)/postgres/assets/data/00-version.sql
_TEST_POSTGRES_SQL_FILE:
	echo "select version();" > $(_TEST_POSTGRES_SQL_FILE)
	gzip -c $(_TEST_POSTGRES_SQL_FILE) > $(_TEST_POSTGRES_SQL_FILE).gz
