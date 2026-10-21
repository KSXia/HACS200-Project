#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./recycle_container.bash [container] [mitmp]"
    exit 1
fi

$container="$1"
$mitmp="$2"

echo "recyling container \"$container\""
echo -n "stopping container.. "
lxc stop "$container" > /dev/null
echo "done"
echo -n "restoring container to base snapshot.. "
lxc restore "$container" "snapshot-base" > /dev/null
echo "done"
echo -n "starting container.. "
lxc start "$container" > /dev/null
echo "done"
echo -n "stopping mitmp.. "
sudo screen -S "$mitmp" -X quit > /dev/null
echo "done"
