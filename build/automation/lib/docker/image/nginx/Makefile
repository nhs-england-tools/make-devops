PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../../../../..))
include $(abspath $(PROJECT_DIR)/build/automation/init.mk)

# ==============================================================================

dependencies: ### Download dependencies - mandatory: INSTANA_AGENT_KEY
	nginx_ver=$$(echo $(DOCKER_NGINX_VERSION) | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')
	nt_ver=$$(curl -s https://github.com/instana/nginx-tracing/releases | \
		grep '/instana/nginx-tracing/releases/tag/' | \
		grep -Eo 'Release [0-9]+\.[0-9]+\.[0-9]+' | \
		grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | \
		head -n 1)
	curl -s \
		https://artifact-public.instana.io/artifactory/shared/com/instana/nginx_tracing/$$nt_ver/linux-amd64-musl-nginx-$$nginx_ver.zip \
		-H "Authorization: Basic $$(echo -n _:$(INSTANA_AGENT_KEY) | base64)" \
		-o $(TMP_DIR)/linux-amd64-musl-nginx-$$nginx_ver.zip
	cd $(TMP_DIR)
	unzip linux-amd64-musl-nginx-$$nginx_ver.zip
	rm -f linux-amd64-musl-nginx-$$nginx_ver.zip
	mv -fv musl-nginx-$$nginx_ver-ngx_http_ot_module.so $(DOCKER_LIB_IMAGE_DIR)/nginx/assets/usr/lib/nginx/modules/ngx_http_opentracing_module.so
	mv -fv musl-libinstana_sensor.so $(DOCKER_LIB_IMAGE_DIR)/nginx/assets/usr/lib/nginx/modules/libinstana_sensor.so

build: project-config _copy-ssl-certificate
	[ -n "$(FORCE)" ] && target=docker-build || target="docker-image-pull-or-build VERSION=$(DOCKER_LIBRARY_NGINX_VERSION) LATEST=true"
	make -s $$target NAME=nginx

test:
	make docker-test NAME=nginx

push:
	make docker-push NAME=nginx

clean:
	make docker-image-clean NAME=nginx

# ==============================================================================

build-example:
	make docker-build NAME=nginx EXAMPLE=true FORCE=true

test-example:
	make docker-test NAME=nginx EXAMPLE=true

run-example:
	make docker-image-start NAME=nginx EXAMPLE=true \
		ARGS=" \
			--workdir /application \
			--publish 8080:8080 \
			--publish 8443:8443 \
			--attach \
			--rm \
		"

# ==============================================================================

_copy-ssl-certificate:
	make ssl-copy-certificate-project DIR=$(DOCKER_LIB_IMAGE_DIR)/nginx/assets/certificate
