#!/bin/bash
set -e

# run init scripts
for file in /sbin/init.d/*; do
  case "$file" in
    *.sh)
      source $file "$@"
      ;;
  esac
done
