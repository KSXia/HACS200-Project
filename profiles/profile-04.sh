#!/bin/bash
# profile-04: SSL key honeypot, static IP 172.16.1.4
PROFILE="profile-04"
IP="172.20.1.4"

if lxc profile show "$PROFILE" &>/dev/null; then
  echo "[INFO] $PROFILE already exists, updating IP only"
else
  echo "[INFO] Creating $PROFILE"
  lxc profile copy default "$PROFILE"
fi

lxc profile device set "$PROFILE" eth0 ipv4.address="$IP"

echo "[INFO] Done"
lxc profile show "$PROFILE"
