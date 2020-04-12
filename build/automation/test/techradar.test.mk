test-techradar: \
	test-techradar-setup \
	test-techradar-inspect-filesystem \
	test-techradar-inspect-image \
	test-techradar-inspect-build \
	test-techradar-teardown

test-techradar-setup:
	make docker-config

test-techradar-teardown:

# ==============================================================================

test-techradar-inspect-filesystem:
	# arrange
	docker pull alpine:$(DOCKER_ALPINE_VERSION)
	# act
	output=$$(make techradar-inspect IMAGE=alpine:$(DOCKER_ALPINE_VERSION))
	name=$$(echo $$output | jq '.filesystem.name' --raw-output)
	version=$$(echo $$output | jq '.filesystem.version' --raw-output)
	# assert
	mk_test "$(@) name" alpine = "$$name"
	mk_test "$(@) version" $(DOCKER_ALPINE_VERSION) = "$$version"

test-techradar-inspect-image:
	# arrange
	docker pull alpine:$(DOCKER_ALPINE_VERSION)
	# act
	output=$$(make techradar-inspect IMAGE=alpine:$(DOCKER_ALPINE_VERSION))
	hash=$$(echo $$output | jq '.image.hash' --raw-output)
	date=$$(echo $$output | jq '.image.date' --raw-output)
	size=$$(echo $$output | jq '.image.size' --raw-output)
	trace=$$(echo $$output | jq '.image.trace' --raw-output)
	# assert
	mk_test "$(@) hash" -n $$hash
	mk_test "$(@) date" -n $$date
	mk_test "$(@) size" 0 -lt $$size
	mk_test "$(@) trace" -n $$trace

test-techradar-inspect-build:
	# arrange
	docker pull alpine:$(DOCKER_ALPINE_VERSION)
	# act
	output=$$(make techradar-inspect IMAGE=alpine:$(DOCKER_ALPINE_VERSION))
	id=$$(echo $$output | jq '.build.id' --raw-output)
	date=$$(echo $$output | jq '.build.date' --raw-output)
	hash=$$(echo $$output | jq '.build.hash' --raw-output)
	repo=$$(echo $$output | jq '.build.repo' --raw-output)
	# assert
	mk_test "$(@) id" -n $$id
	mk_test "$(@) date" -n $$date
	mk_test "$(@) hash" -n $$hash
	mk_test "$(@) repo" -n $$repo
