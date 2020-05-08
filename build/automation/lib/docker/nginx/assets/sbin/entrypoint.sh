#!/bin/bash
set -e

if [ $# -gt 0 ]; then
  # Run command
  exec "$@"
else
  # Run init scripts
  for file in /sbin/init.d/*; do
    case "$file" in
      *.sh)
        source $file "$@"
        ;;
    esac
  done
  # Run main process
  exec nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
fi
