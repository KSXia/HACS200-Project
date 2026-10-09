#!/bin/bash

if [[ $# -ne 4 ]]
then
  echo "[Usage]: ./creation.sh [image] [profile] [mitm config file] [mitm process name]"
  exit 1
fi


echo "[!] Launching Container"
profile_num="${$2: -2}"
container_name="$1-$profile_num"
lxc launch $1 $container_name -p $2 > /dev/null
lxc exec $container_name -- sudo systemctl restart ssh

# ---TODO---
# Change MITM configuration to be based on profile (this may also require making multiple jsons for each profile
echo "[!] Starting MITM.."
sudo screen -dmS $4 node /root/honeypots/MITM/mitm/index.js $3

