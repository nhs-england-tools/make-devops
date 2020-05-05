#!/bin/bash
set -e

DOMAIN=${DOMAIN:-localhost}
SSL_CERTIFICATE_NAME=${SSL_CERTIFICATE_NAME:-certificate}

function main() {
  prepare_configuration_files
}

function prepare_configuration_files() {
  for template in $(ls -1 /etc/nginx/*.template /etc/nginx/conf.d/*.template 2> /dev/null); do
    file=$(echo $template | sed "s;.template;;g")
    cp -fv $template $file
    _replace_variables $file
  done
}

function _replace_variables() {
  file=$1
  echo "Replace variables in '$file'"
  for str in $(cat $file | grep -Eo "[A-Za-z0-9_]*_TO_REPLACE" | sort | uniq); do
    key=$(cut -d "=" -f1 <<<"$str" | sed "s/_TO_REPLACE//g")
    value=$(echo $(eval echo "\$$key"))
    [ -z "$value" ] && echo "WARNING: Variable $key has no value in '$file'" || sed -i \
      "s;${key}_TO_REPLACE;${value//&/\\&};g" \
      $file ||:
  done
}

main "$@"
