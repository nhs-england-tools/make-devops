PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))/../../..))
include $(abspath $(lastword $(MAKEFILE_LIST))/../../../automation/init.mk)

# ==============================================================================

build:
	make \
		_generate_ssl_certificate \
		_nginx_index_html_file
	make docker-build NAME=nginx

test:
	make docker-test NAME=nginx ARGS=" \
		--env PROJECT_GROUP_SHORT=$(PROJECT_GROUP_SHORT) \
		--env PROJECT_NAME_SHORT=$(PROJECT_NAME_SHORT) \
	"

push:
	make docker-push NAME=nginx

clean:
	make docker-image-clean NAME=nginx
	find $(DOCKER_DIR)/nginx/assets/application -mindepth 1 -maxdepth 1 -not -name '.gitignore' -print | xargs rm -rfv
	find $(DOCKER_DIR)/nginx/assets/certificate -mindepth 1 -maxdepth 1 -not -name '.gitignore' -print | xargs rm -rfv

# ==============================================================================

_generate_ssl_certificate:
	if [ ! -f $(DOCKER_DIR)/nginx/assets/certificate/nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).pem ]; then
		make ssl-generate-certificate-project \
			DIR=$(DOCKER_DIR)/nginx/assets/certificate \
			NAME=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT) \
			DOMAINS=nginx.$(PROJECT_NAME_SHORT)-$(PROJECT_GROUP_SHORT).local
	fi

_NGINX_INDEX_HTML_FILE := $(DOCKER_DIR)/nginx/assets/application/index.html
_nginx_index_html_file:
	echo '<!doctype html>' > $(_NGINX_INDEX_HTML_FILE)
	echo '<html lang="en">' >> $(_NGINX_INDEX_HTML_FILE)
	echo '<body>Welcome to Make DevOps!</body>' >> $(_NGINX_INDEX_HTML_FILE)
	echo '</html>' >> $(_NGINX_INDEX_HTML_FILE)
