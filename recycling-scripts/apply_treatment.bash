#!/bin/bash
set -euo pipefail

if [ -z "$MITM_HOME_DIR" ]; then
    printf 'no home directory for %q\n' "$MITM_USERNAME" >&2
    exit 1
fi

treatment=$(cat treatment.txt)

if [[ "$treatment" == "ssh" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- rm -rf /AI-Powered-Tutor
  lxc exec $MITM_CONTAINER_NAME -- mv /.ssh -- "$MITM_HOME_DIR/"
elif [[ "$treatment" == "ssl" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- rm -rf /AI-Powered-Tutor
  lxc exec $MITM_CONTAINER_NAME -- rm -rf /.ssh
elif [[ "$treatment" == "api" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- mv /AI-Powered-Tutor/.env -- "$MITM_HOME_DIR/.env"
  lxc exec $MITM_CONTAINER_NAME -- rm -rf /.ssh
else
  lxc exec $MITM_CONTAINER_NAME -- rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- rm -rf /AI-Powered-Tutor -- "$MITM_HOME_DIR/.env"
  lxc exec $MITM_CONTAINER_NAME -- rm -rf .ssh
fi

