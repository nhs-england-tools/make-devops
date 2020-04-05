#!/bin/bash
set -e

function main() {
    DB_HOST=${DB_HOST:-postgres}
    DB_PORT=${DB_PORT:-5432}
    DB_NAME=${DB_NAME:-postgres}
    DB_USERNAME=${DB_USERNAME:-${DB_MASTER_USERNAME:-postgres}}
    DB_PASSWORD=${DB_PASSWORD:-${DB_MASTER_PASSWORD:-postgres}}
    if [ "$1" == "-c" ] && [ -n "$2" ]; then
        # Run a provided SQL statement
        SQL="$2"
        psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -c "$SQL"
    else
        # Run specified SQL scripts
        DIR=${1-}
        FILES=${2-*.sql}
        for file in /sql/$DIR/*; do
            case "$file" in
                $FILES)
                    echo "$0: running $file"
                    replace_variables $file
                    psql "postgres://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -f $file
                    ;;
            esac
        done
    fi
}

function replace_variables() {
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
