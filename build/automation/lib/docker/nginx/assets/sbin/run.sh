#!/bin/bash
set -e

exec $trace $gosu nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
