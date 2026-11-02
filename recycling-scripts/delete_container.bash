#!/bin/bash

# [container] is the unique container name
# [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./delete_container.bash [container] [mitmp]"
    exit 1
fi

container="$1"
mitmp="$2"

echo "deleting container \"$container\""
echo -n "stopping container.. "
# lxc stop waits forever by default, so force the stop if it takes more than 30 seconds
lxc stop "$container" --timeout 30 > /dev/null 2>&1 || lxc stop "$container" --force > /dev/null
echo "done"
echo -n "deleting container.. "
lxc delete "$container" --force > /dev/null
echo "done"
./stop_mitm.bash "$container" "$mitmp"
