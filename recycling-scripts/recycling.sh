#!/bin/bash

if [[ $# -ne 3 ]]
then
  echo "[Usage]: ./recycling.sh [container name] [mitm process name] [hard|soft]"
  exit 1
fi

container="$1"
mitm_name="$2"
mode="$3"
base_snapshot="base"

case "$mode" in
  hard)
    echo "[!] Hard reset: deleting container..."
    lxc stop "$container" > /dev/null
    lxc delete "$container" > /dev/null
    ;;
  soft)
    echo "[!] Soft reset: reverting to snapshot '$base_snapshot'..."
    lxc stop "$container" > /dev/null
    lxc restore "$container" "$base_snapshot" > /dev/null
    lxc start "$container" > /dev/null
    ;;
  *)
    echo "[Error]: reset type must be 'hard' or 'soft'"
    exit 1
    ;;
esac

echo "[!] Stopping MITM process..."
sudo screen -S "$mitm_name" -X quit > /dev/null
