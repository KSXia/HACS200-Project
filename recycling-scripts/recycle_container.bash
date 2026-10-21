#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./recycle_container.bash [container] [mitmp]"
    exit 1
fi

echo "recyling container \"$1\""
echo -n "stopping container.. "
lxc stop "$1" > /dev/null
echo "done"
echo -n "restoring container to base snapshot.. "
lxc restore "$1" "snapshot-base" > /dev/null
echo "done"
echo -n "starting container.. "
lxc start "$1" > /dev/null
echo "done"
echo -n "stopping mitmp.. "
sudo screen -S "$2" -X quit > /dev/null
echo "done"
