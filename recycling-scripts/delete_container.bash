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
lxc stop "$container" > /dev/null
echo "done"
echo -n "deleting container.. "
lxc delete "$container" > /dev/null
echo "done"
echo -n "stopping mitmp.. "
sudo screen -S "$mitmp" -X quit > /dev/null
sudo screen -S "$container-logins" -X quit > /dev/null
sudo screen -S "$container-attempts" -X quit > /dev/null
echo "done"
