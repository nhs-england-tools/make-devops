#!/bin/bash
set -e

[[ "$DEBUG" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && set -x
[[ "$TRACE" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && export trace="strace -tt -T -v -s 65536 -f"
[[ "$GOSU" =~ ^(false|no|off|0|FALSE|NO|OFF)$ ]] && export gosu="" || export gosu="gosu $SYSTEM_USER"
export SYSTEM_USER_UID=${DEV_USER_UID:-$SYSTEM_USER_UID} && usermod -u $SYSTEM_USER_UID $SYSTEM_USER
export SYSTEM_USER_GID=${DEV_USER_GID:-$SYSTEM_USER_GID} && groupmod -g $SYSTEM_USER_GID $SYSTEM_USER

# Run init scripts
for file in /sbin/init.d/*; do
  case "$file" in
    *.sh)
      source $file "$@"
      ;;
  esac
done
# Run main process
source /sbin/run.sh
