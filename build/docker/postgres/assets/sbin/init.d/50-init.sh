#!/bin/bash
set -e

DB_HOST=${DB_HOST:-postgres}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-postgres}
DB_USERNAME=${DB_USERNAME:-postgres}
DB_PASSWORD=${DB_PASSWORD:-postgres}

function main() {
  if [ "sql" == "$1" ]; then
    shift
    run_sql "$@"
  elif [ "scripts" == "$1" ]; then
    shift
    run_scripts "$@"
  elif [ "postgres" == "$1" ]; then
    run_postgres
  else
    exec "$@"
  fi
}

function run_sql() {
  sql="$1"
  echo "Running SQL: $sql"
  psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -c "$sql"
}

function run_scripts() {
  dir=${1:-/sql}
  for file in $dir/*; do
    echo "Running script: '$file'"
    _replace_variables $file
    psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -f $file
  done
}

function run_postgres() {
  for file in /docker-entrypoint-initdb.d/*; do
    _replace_variables $file
  done
  exec /usr/local/bin/docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf
}

function _replace_variables() {
  file=$1
  for str in $(cat $file | grep -Eo "[A-Za-z0-9_]*_TO_REPLACE" | sort | uniq); do
    key=$(cut -d "=" -f1 <<<"$str" | sed "s/_TO_REPLACE//g")
    value=$(echo $(eval echo "\$$key"))
    [ -z "$value" ] && echo "WARNING: Variable $key has no value in '$file'" || sed -i \
      "s;${key}_TO_REPLACE;${value//&/\\&};g" \
      $file ||:
  done
}

main "$@"
