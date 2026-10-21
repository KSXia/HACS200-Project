#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
if [[ $# -ne 1 ]]; then
    echo "usage: ./recycle_container.bash [container]"
    exit 1
fi

echo "deleting container \"$1\""
echo -n "stopping container.. "
lxc stop "$1" > /dev/null
echo "done"
echo -n "deleting container.. "
lxc delete "$1" > /dev/null
echo "done"
