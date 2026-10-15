#!/bin/bash

if [[ $# -ne 3 ]]
then
  echo "[Usage]: ./creation.sh [treatment] [number] [mitm process name]"
  exit 1
fi


echo "[!] Launching Container"
container_name="cont-$2"
lxc launch base-img $container_name -p profile-$2 > /dev/null
sudo cp -r ../container-files/$1-cont /var/snap/lxd/common/mntns/var/snap/lxd/common/lxd/storage-pools/default/containers/$container_name/rootfs/root/

# ---TODO---
# Change MITM configuration to be based on profile (this may also require making multiple jsons for each profile
echo "[!] Starting MITM.."
sudo screen -L -Logfile log-$2 -dmS $3 sudo node /root/honeypots/MITM/mitm/index.js cont-$2

