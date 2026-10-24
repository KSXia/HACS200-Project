#!/bin/bash
set -euo pipefail

if [ -z "$MITM_HOME_DIR" ]; then
    printf 'no home directory for %q\n' "$MITM_USERNAME" >&2
    exit 1
fi

treatment=$(cat .treatment.txt)

lxc exec $MITM_CONTAINER_NAME -- sudo mv -f /AI-Powered-Tutor -- "$MITM_HOME_DIR/"

if [[ "$treatment" == "ssh" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf -- "$MITM_HOME_DIR/.ssh"
  lxc exec $MITM_CONTAINER_NAME -- sudo mv -f /.ssh -- "$MITM_HOME_DIR/"
elif [[ "$treatment" == "ssl" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
elif [[ "$treatment" == "api" ]]
then
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo mv -f /.env -- "$MITM_HOME_DIR/AI-Powered-Tutor/.env"
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
else
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /etc/ssl/private/private.key
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -f /.env
  lxc exec $MITM_CONTAINER_NAME -- sudo rm -rf /.ssh
fi
