#!/bin/bash
set -e

DB_HOST=${DB_HOST:-postgres}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-postgres}
DB_USERNAME=${DB_USERNAME:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}

function main() {
  if [ "scripts" == "$1" ]; then
    replace_variables_in_scripts "$@"
  elif [ "postgres" == "$1" ] || [ $# -eq 0 ]; then
    replace_variables_in_postgres
  fi
  set_file_permissions
}

function replace_variables_in_scripts() {
  dir=${2:-/sql}
  for file in $dir/*; do
    [ -f $file ] && _replace_variables $file ||:
  done
}

function replace_variables_in_postgres() {
  for file in /docker-entrypoint-initdb.d/*; do
    [ -f $file ] && _replace_variables $file ||:
  done
}

function set_file_permissions() {
  chmod 0600 /etc/postgresql/certificate.*
  chown -R $SYSTEM_USER_UID:$SYSTEM_USER_GID /etc/postgresql
  find /sql -type d -exec chmod 777 {} \;
  find /sql -type f -exec chmod 666 {} \;
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
