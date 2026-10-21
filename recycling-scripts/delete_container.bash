#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./delete_container.bash [container] [mitmp]"
    exit 1
fi

echo "deleting container \"$1\""
echo -n "stopping container.. "
lxc stop "$1" > /dev/null
echo "done"
echo -n "deleting container.. "
lxc delete "$1" > /dev/null
echo "done"
echo -n "stopping mitmp.. "
sudo screen -S "$2" -X quit > /dev/null
echo "done"
