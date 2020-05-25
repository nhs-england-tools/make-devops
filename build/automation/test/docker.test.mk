TEST_DOCKER_IMAGE = postgres

test-docker:
	make test-docker-setup
	tests=( \
		test-docker-config \
		test-docker-build \
		test-docker-image-name-as \
		test-docker-image-keep-latest-only \
		test-docker-login \
		test-docker-create-repository \
		test-docker-push \
		test-docker-pull \
		test-docker-create-dockerfile \
		test-docker-set-get-image-version \
		test-docker-image-start \
		test-docker-image-stop \
		test-docker-image-log \
		test-docker-image-bash \
		test-docker-image-clean \
		test-docker-image-save \
		test-docker-image-load \
		test-docker-tag \
		test-docker-get-variables-from-file \
		test-docker-run-dotnet \
		test-docker-run-gradle \
		test-docker-run-mvn \
		test-docker-run-node \
		test-docker-run-python-single-cmd \
		test-docker-run-python-multiple-cmd \
		test-docker-run-python-multiple-cmd-pip-install \
		test-docker-run-terraform \
		test-docker-run-tools-single-cmd \
		test-docker-run-tools-multiple-cmd \
		test-docker-run-pass-variables \
		test-docker-run-do-not-pass-empty-variables \
		test-docker-run-specify-image \
		test-docker-nginx-image \
		test-docker-postgres-image \
		test-docker-tools-image \
		test-docker-compose \
		test-docker-compose-single-service \
		test-docker-compose-parallel-execution \
		test-docker-clean \
		test-docker-prune \
	)
	for test in $${tests[*]}; do
		mk_test_initialise $$test
		make $$test
	done
	make test-docker-teardown

test-docker-setup:
	docker rm -f $(docker ps -a -q) 2> /dev/null ||:

test-docker-teardown:
	rm -rf $(TEST_DOCKER_COMPOSE_YML)
	make docker-prune

# ==============================================================================

test-docker-config:
	# act
	make docker-config
	# assert
	mk_test "$(DOCKER_NETWORK) = $$(docker network ls | grep -Eo $(DOCKER_NETWORK))"

test-docker-build:
	# act
	make docker-build NAME=$(TEST_DOCKER_IMAGE) FROM_CACHE=true
	# assert
	mk_test "1 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/$(TEST_DOCKER_IMAGE):latest -q | wc -l)"

test-docker-image-name-as:
	# act
	make docker-build NAME=$(TEST_DOCKER_IMAGE) NAME_AS=$(TEST_DOCKER_IMAGE)-copy FROM_CACHE=true
	# assert
	mk_test "2 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/$(TEST_DOCKER_IMAGE)-copy:* --quiet | wc -l)"

test-docker-image-keep-latest-only:
	# act
	make docker-build NAME=$(TEST_DOCKER_IMAGE) FROM_CACHE=true
	make docker-build NAME=$(TEST_DOCKER_IMAGE) FROM_CACHE=true
	make docker-build NAME=$(TEST_DOCKER_IMAGE) FROM_CACHE=true
	# assert
	mk_test "2 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/$(TEST_DOCKER_IMAGE):* -q | wc -l)"

test-docker-login:
	mk_test_skip

test-docker-create-repository:
	mk_test_skip

test-docker-push:
	mk_test_skip

test-docker-pull:
	mk_test_skip

test-docker-clean:
	# act
	make docker-clean
	# assert
	mk_test "0 -eq $$(find $(DOCKER_LIBRARY_DIR) -type f -name '.version' | wc -l)"

test-docker-prune:
	# act
	make docker-prune
	# assert
	mk_test "images" "0 -eq $$(docker images | grep $(DOCKER_LIBRARY_REGISTRY) 2> /dev/null | wc -l)"
	mk_test "network" "0 -eq $$(docker network ls | grep $(DOCKER_NETOWRK) 2> /dev/null | wc -l)"
	mk_test_complete

test-docker-create-dockerfile:
	# act
	make docker-create-dockerfile NAME=$(TEST_DOCKER_IMAGE)
	# assert
	mk_test "-n \"$$(cat $(DOCKER_LIBRARY_DIR)/$(TEST_DOCKER_IMAGE)/Dockerfile.effective | grep -Eo METADATA | wc -l)\""

test-docker-set-get-image-version:
	# arrange
	cp -rf $(DOCKER_LIBRARY_DIR)/$(TEST_DOCKER_IMAGE) $(TMP_DIR)
	echo "YYYYmmddHHMM-hash" > $(TMP_DIR)/$(TEST_DOCKER_IMAGE)/VERSION
	# act
	make docker-set-image-version NAME=$(TEST_DOCKER_IMAGE) DOCKER_CUSTOM_DIR=$(TMP_DIR)
	version=$$(make docker-get-image-version NAME=$(TEST_DOCKER_IMAGE) DOCKER_CUSTOM_DIR=$(TMP_DIR))
	# assert
	mk_test "$$version = $$(date --date=$(BUILD_DATE) -u +%Y%m%d%H%M)-$$(git rev-parse --short HEAD)"

test-docker-image-start:
	# arrange
	docker rm --force postgres-$(BUILD_HASH)-$(BUILD_ID) 2> /dev/null ||:
	make docker-build NAME=postgres FROM_CACHE=true
	# act
	make docker-image-start NAME=postgres \
		ARGS="--env POSTGRES_PASSWORD=postgres" \
		CMD="postgres"
	sleep 1
	# assert
	mk_test "1 -eq $$(docker ps | grep postgres-$(BUILD_HASH)-$(BUILD_ID) | wc -l)"

test-docker-image-stop:
	# arrange
	docker rm --force postgres-$(BUILD_HASH)-$(BUILD_ID) 2> /dev/null ||:
	make docker-build NAME=postgres FROM_CACHE=true
	make docker-image-start NAME=postgres \
		ARGS="--env POSTGRES_PASSWORD=postgres" \
		CMD="postgres"
	sleep 1
	# act
	make docker-image-stop NAME=postgres
	# assert
	mk_test "0 -eq $$(docker ps | grep postgres-$(BUILD_HASH)-$(BUILD_ID) | wc -l)"

test-docker-image-log:
	mk_test_skip

test-docker-image-bash:
	mk_test_skip

test-docker-image-clean:
	# arrange
	make docker-build NAME=postgres FROM_CACHE=true
	# act
	make docker-image-clean NAME=postgres
	# assert
	mk_test "0 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/postgres:* --quiet | wc -l)"

test-docker-image-save:
	# arrange
	make docker-image-clean NAME=postgres
	make docker-build NAME=postgres FROM_CACHE=true
	# act
	make docker-image-save NAME=postgres
	# assert
	mk_test "1 -eq $$(ls $(DOCKER_LIBRARY_DIR)/postgres/postgres-*-image.tar.gz | wc -l)"

test-docker-image-load:
	# arrange
	make docker-image-clean NAME=postgres
	make docker-build NAME=postgres FROM_CACHE=true
	make docker-image-save NAME=postgres
	docker rmi --force $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/postgres:* --quiet) 2> /dev/null ||:
	# act
	make docker-image-load NAME=postgres
	# assert
	mk_test "1 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/postgres:* --quiet | wc -l)"

test-docker-tag:
	# arrange
	make docker-image-clean NAME=postgres
	make docker-build NAME=postgres FROM_CACHE=true
	# act
	make docker-tag NAME=postgres VERSION=version
	# assert
	mk_test "1 -eq $$(docker images --filter=reference=$(DOCKER_LIBRARY_REGISTRY)/postgres:version --quiet | wc -l)"

test-docker-get-variables-from-file:
	# act
	vars=$$(make _docker-get-variables-from-file VARS_FILE=$(VAR_DIR)/project.mk.default)
	# assert
	mk_test "PROJECT_NAME= = $$(echo \"$$vars\" | grep -o PROJECT_NAME=)"

test-docker-run-dotnet:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-dotnet \
			CMD="--info" \
		| grep -Eo ".NET Core SDK" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-gradle:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-gradle \
			CMD="gradle --version" \
		| grep -Eo "Gradle" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-mvn:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-mvn \
			CMD="--version" \
		| grep -Eo "Apache Maven" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-node:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-node \
			CMD="npm --version" \
		| grep -Eo "[(0-9)]*.[(0-9)]*" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-python-single-cmd:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-python \
			CMD="python3 --version" \
		| grep -Eo "Python" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-python-multiple-cmd:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-python SH=y \
			CMD="python3 --version && pip3 --version" \
		| grep -Eo "Python" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-python-multiple-cmd-pip-install:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-python SH=y \
			CMD="pip3 install django > /dev/null 2>&1 && pip3 list" \
		| grep -i "django" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-terraform:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-terraform \
			CMD="terraform --version" \
		| grep -Eo "Terraform" | wc -l)
	# assert
	mk_test "0 -lt $$output"

test-docker-run-tools-single-cmd:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-tools \
			CMD="apt list --installed" \
		| sed 's/\x1b\[[0-9;]*m//g' | grep -E -- '^curl/now' | wc -l)
	# assert
	mk_test "1 -eq $$output"

test-docker-run-tools-multiple-cmd:
	# arrange
	make docker-config
	# act
	output=$$(
		make docker-run-tools SH=y \
			CMD="cat /etc/issue && apt list --installed" \
		| sed 's/\x1b\[[0-9;]*m//g' | grep -Ei -- '^(debian gnu/linux|curl/now)' | wc -l)
	# assert
	mk_test "2 -eq $$output"

test-docker-run-pass-variables:
	# arrange
	make docker-config
	# act
	export PROJECT_NON_EMPTY_VAR=value
	output=$$(make -s docker-run-tools CMD=env | grep PROJECT_NON_EMPTY_VAR | wc -l)
	# assert
	mk_test "1 -eq $$output"

test-docker-run-do-not-pass-empty-variables:
	# arrange
	make docker-config
	# act
	export PROJECT_EMPTY_VAR=
	output=$$(make -s docker-run-tools CMD=env | grep PROJECT_EMPTY_VAR | wc -l)
	# assert
	mk_test "0 -eq $$output"

test-docker-run-specify-image:
	# arrange
	make docker-config
	# act
	output=$$(make -s docker-run-python IMAGE=python:3.7.0 CMD="python --version" | grep "3.7.0" | wc -l)
	# assert
	mk_test "1 -eq $$output"

test-docker-nginx-image:
	# arrange
	cd $(DOCKER_LIBRARY_DIR)/nginx
	# act
	make build test
	# assert
	mk_test true
	# clean up
	make clean

test-docker-postgres-image:
	# arrange
	cd $(DOCKER_LIBRARY_DIR)/postgres
	# act
	make build test
	# assert
	mk_test true
	# clean up
	make clean

test-docker-tools-image:
	# arrange
	cd $(DOCKER_LIBRARY_DIR)/tools
	# act
	make build test
	# assert
	mk_test true
	# clean up
	make clean

test-docker-compose:
	# arrange
	make TEST_DOCKER_COMPOSE_YML
	# act & assert
	make docker-compose-stop docker-compose-start YML=$(TEST_DOCKER_COMPOSE_YML) && \
		mk_test "start" "true" || mk_test "start" "false"
	make docker-compose-log YML=$(TEST_DOCKER_COMPOSE_YML) DO_NOT_FOLLOW=true && \
		mk_test "log" "true" || mk_test "log" "false"
	make docker-compose-stop YML=$(TEST_DOCKER_COMPOSE_YML) && \
		mk_test "stop" "true" || mk_test "stop" "false"
	mk_test_complete

test-docker-compose-single-service:
	# arrange
	make TEST_DOCKER_COMPOSE_YML
	# act & assert
	make docker-compose-stop docker-compose-start-single-service NAME=alpine YML=$(TEST_DOCKER_COMPOSE_YML) && \
		mk_test "start" "true" || mk_test "start" "false"
	make docker-compose-log YML=$(TEST_DOCKER_COMPOSE_YML) DO_NOT_FOLLOW=true && \
		mk_test "log" "true" || mk_test "log" "false"
	make docker-compose-stop YML=$(TEST_DOCKER_COMPOSE_YML) && \
		mk_test "stop" "true" || mk_test "stop" "false"
	mk_test_complete

test-docker-compose-parallel-execution:
	# arrange & act
	make TEST_DOCKER_COMPOSE_YML
	make \
		docker-compose-stop \
		docker-compose-start \
		YML=$(TEST_DOCKER_COMPOSE_YML) \
		BUILD_ID=$(BUILD_ID)_1
	make TEST_DOCKER_COMPOSE_YML
	make \
		docker-compose-stop \
		docker-compose-start \
		YML=$(TEST_DOCKER_COMPOSE_YML) \
		BUILD_ID=$(BUILD_ID)_2
	# assert
	mk_test "2 -eq $$(docker ps --all --filter "name=.*-$(BUILD_ID)_[1|2]" --quiet | wc -l)"
	# clean up
	docker rm --force --volumes $$(docker ps --all --filter "name=.*-$(BUILD_ID)_[1|2]" --quiet) #2> /dev/null ||:
	docker network rm $$(docker network ls --filter "name=$(PROJECT_GROUP)/$(PROJECT_NAME)/$(BUILD_ID)_[1|2]" --quiet)

# ==============================================================================

TEST_DOCKER_COMPOSE_YML = $(TMP_DIR)/docker-compose.yml
TEST_DOCKER_COMPOSE_YML:
	echo 'version: "3.7"' > $(TEST_DOCKER_COMPOSE_YML)
	echo "services:" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "  alpine:" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "    image: alpine:latest" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "    container_name: alpine" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "    hostname: alpine" >> $(TEST_DOCKER_COMPOSE_YML)
	echo '    command: [ "sh" ]' >> $(TEST_DOCKER_COMPOSE_YML)
	echo "networks:" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "  default:" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "    external:" >> $(TEST_DOCKER_COMPOSE_YML)
	echo "      name: \$$DOCKER_NETWORK" >> $(TEST_DOCKER_COMPOSE_YML)
