#!/bin/bash

if [[ $# -ne 3 ]]
then
  echo "[Usage]: ./creation.sh [treatment] [number] [mitm process name]"
  exit 1
fi

container_name="cont-$2"

if lxc info "$container_name" > /dev/null 2>&1
then
  echo "[!] $container_name already exists, skipping launch"
else
  echo "[!] Launching Container"
  lxc launch base-img "$container_name" -p profile-$2 > /dev/null
  # Snapshot the clean container before any treatment is applied
  lxc snapshot "$container_name" base
fi

# ---TODO---
# Change MITM configuration to be based on profile (this may also require making multiple jsons for each profile
echo "[!] Starting MITM.."
: > log-$2    # truncate old log so stale "connection closed" lines can't match
sudo screen -L -Logfile log-$2 -dmS $3 sudo node /root/honeypots/MITM/mitm/index.js cont-$2
