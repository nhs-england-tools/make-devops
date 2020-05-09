#!/bin/bash
set -e

function configure() {
  [[ "$DEBUG" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && set -x
  [[ "$TRACE" =~ ^(true|yes|on|1|TRUE|YES|ON)$ ]] && export trace="strace -tt -T -v -s 65536 -f"
  [[ "$GOSU" =~ ^(false|no|off|0|FALSE|NO|OFF)$ ]] && export gosu="" || export gosu="gosu $SYSTEM_USER"
  # Sync user ID for development
  if [ -n "$DEV_USER_UID" ]; then
    cat /etc/passwd | grep -q "x:$DEV_USER_UID:" && userdel --remove --force $(id -nu $DEV_USER_UID)
    export SYSTEM_USER_UID=$DEV_USER_UID
    usermod -u $SYSTEM_USER_UID $SYSTEM_USER
  fi
  # Sync group ID with development
  if [ -n "$DEV_USER_GID" ]; then
    cat /etc/group | grep -q ":$DEV_USER_GID:" && groupdel $(getent group $DEV_USER_GID | cut -d: -f1)
    export SYSTEM_USER_GID=$DEV_USER_GID
    groupmod -g $SYSTEM_USER_GID $SYSTEM_USER
  fi
}

# Configure
configure
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
