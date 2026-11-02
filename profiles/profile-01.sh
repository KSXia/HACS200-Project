#!/bin/bash
# profile-01: static IP 172.20.1.1 for cont-01 (the treatment is picked at random each session)
PROFILE="profile-01"
IP="172.20.1.1"

if lxc profile show "$PROFILE" &>/dev/null; then
  echo "[INFO] $PROFILE already exists, updating IP only"
else
  echo "[INFO] Creating $PROFILE"
  lxc profile copy default "$PROFILE"
fi

lxc profile device set "$PROFILE" eth0 ipv4.address="$IP"

echo "[INFO] Done"
lxc profile show "$PROFILE"
