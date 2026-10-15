#!/bin/bash
# profile-01: control honeypot (no key files), static IP 172.16.1.1
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
