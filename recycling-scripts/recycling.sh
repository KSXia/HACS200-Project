#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo "[Usage]: ./recycling.sh [container name] [mitm process name]"
  exit 1
fi

echo "[!] Deleting container..."
lxc stop $1 > /dev/null
lxc delete $1 > /dev/null
echo "[!] Stopping MITM process..."
sudo screen -S $2 -X quit > /dev/null


