#!/bin/bash
set -euo pipefail

if [ -z "$MITM_HOME_DIR" ]; then
    printf 'no home directory for %q\n' "$MITM_USERNAME" >&2
    exit 1
fi

treatment=$(cat treatment.txt)

lxc exec $MITM_CONTAINER_NAME -- sudo mv /AI-Powered-Tutor -- "$MITM_HOME_DIR/"

if [[ "$treatment" == "ssh" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo mv /.ssh -- "$MITM_HOME_DIR/"
elif [[ "$treatment" == "ssl" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
elif [[ "$treatment" == "api" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo mv /.env -- "$MITM_HOME_DIR/AI-Powered-Tutor/.env"
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
else
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo rm /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
fi

