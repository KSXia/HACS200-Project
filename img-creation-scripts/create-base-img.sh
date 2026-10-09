#!/bin/bash

if [[ $# -ne 0 ]]
then
  echo "[Usage]: ./create_base_img.sh"
  exit 1
fi

lxc image delete base-img
lxc info base-img &>/dev/null && (lxc stop base-img; lxc delete base-img)

echo "[INFO] Launching Container "
lxc launch ubuntu:20.04 base-img > /dev/null

echo "[INFO] Installing sshd"
sleep 3 # Trust me this is extremely important the container needs time to update it's hostname before using sudo commands
lxc exec base-img -- sudo apt-get install openssh-server >/dev/null
lxc exec base-img -- sudo rm -rf /etc/ssh/sshd_config.d
lxc exec base-img -- bash -c "sudo echo PasswordAuthentication yes > /etc/ssh/sshd_config"
lxc exec base-img -- bash -c "sudo echo PubkeyAuthentication no >> /etc/ssh/sshd_config"
lxc exec base-img -- bash -c "sudo echo PermitRootLogin yes >> /etc/ssh/sshd_config"
lxc exec base-img -- sudo systemctl stop ssh >/dev/null

echo "[INFO] Creating git repository"
# ---TODO--- 
# Implement code to create a fake git repo

echo "[INFO] Completed base image setup"

echo "[INFO] Stopping container"
lxc stop base-img

echo "[INFO] Publishing image"
lxc publish base-img --alias base-img
lxc delete base-img

echo "[INFO] Image creation complete!"


