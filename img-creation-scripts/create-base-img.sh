#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "[Usage]: ./create_base_img.sh [image name]"
  exit 1
fi

echo "[INFO] Launching Container \"$1\""
lxc launch ubuntu:20.04 $1 > /dev/null

echo "[INFO] Installing sshd"
sleep 10 # Trust me this is extremely important the container needs time to update it's hostname before using sudo commands
lxc exec $1 -- sudo apt-get install openssh-server >/dev/null
lxc exec $1 -- sudo rm -rf /etc/ssh/sshd_config.d
lxc exec $1 -- bash -c "sudo echo PasswordAuthentication yes > /etc/ssh/sshd_config"
lxc exec $1 -- bash -c "sudo echo PubkeyAuthentication no >> /etc/ssh/sshd_config"
lxc exec $1 -- bash -c "sudo echo PermitRootLogin yes >> /etc/ssh/sshd_config"
lxc exec $1 -- sudo systemctl restart ssh >/dev/null

echo "[INFO] Creating git repository"
# ---TODO--- 
# Implement code to create a fake git repo

echo "[INFO] Completed base setup for \"$1\""



