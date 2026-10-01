#!/bin/bash

if [[ $# -ne 4 ]]
then
  echo "[Usage]: ./creation.sh [profile] [container name] [mitm config file] [mitm process name]"
  exit 1
fi

echo "[!] Launching Container"
lxc launch ubuntu:20.04 $2 -p $1 > /dev/null
echo "[!] Installing ssh..."
sleep 3 # Trust me this is extremely important the container needs time to update it's hostname before using sudo commands
lxc exec $2 -- sudo apt-get install openssh-server >/dev/null
lxc exec $2 -- bash -c "sudo echo PasswordAuthentication yes > /etc/ssh/sshd_config"
lxc exec $2 -- bash -c "sudo echo PubkeyAuthentication no >> /etc/ssh/sshd_config"
lxc exec $2 -- bash -c "sudo echo PermitRootLogin yes >> /etc/ssh/sshd_config"
lxc exec $2 -- sudo systemctl restart ssh >/dev/null
echo "[!] Starting MITM.."
sudo screen -dmS $4 node /root/honeypots/MITM/mitm/index.js $3

