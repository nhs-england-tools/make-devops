#!/bin/bash
set -e

if [ "sql" == "$1" ]; then
  sql="$2"
  echo "Running SQL: $sql"
  exec $trace $gosu psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -c "$sql"
elif [ "scripts" == "$1" ]; then
  dir=${2:-/sql}
  for file in $dir/*; do
    echo "Running script: '$file'"
    exec $trace $gosu psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -f $file
  done
elif [ "postgres" == "$1" ] || [ $# -eq 0 ]; then
  exec /usr/local/bin/docker-entrypoint.sh postgres -c config_file=/etc/postgresql/postgresql.conf
elif [ $# -gt 0 ]; then
  exec $trace $gosu "$@"
fi
