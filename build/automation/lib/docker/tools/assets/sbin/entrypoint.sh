#!/bin/bash
set -e

[[ "$DEBUG" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && set -x
[[ "$TRACE" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && export trace="strace -tt -T -v -s 65536 -f"
[[ "$GOSU" =~ ^(false|no|off|0|FALSE|NO|OFF)$ ]] && export gosu="" || export gosu="gosu $SYSTEM_USER"

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
  exec /sbin/run.sh
fi
