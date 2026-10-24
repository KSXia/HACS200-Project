#!/bin/bash

# [profile] is the unique profile name associated with an IP address
# [container] is the unique container name
# [mitmp] is the unique MITM process name
if [[ $# -ne 3 ]]; then
    echo "usage: ./creation.bash [profile] [container] [mitmp]"
    exit 1
fi

profile="$1"
container="$2"
mitmp="$3"
mitmconf="${container}.js"

echo "creating MITM container \"$container\":"
echo "    profile \"$profile\""
echo "    MITM process name \"$mitmp\""

if lxc info "$container" &> /dev/null; then
    # container already exists
    echo "container \"$container\" already exists; skipping basic initialization"
else
    # container does not exist
    echo -n "launching container.. "
    lxc launch base-img "$container" -p "$profile" 1> /dev/null
    echo "done"
    echo -n "creating base snapshot.. "
    lxc snapshot "$container" snapshot-base
    echo "done"
fi

echo -n "starting MITM process.. "
# truncate old log
sudo rm ".logs/$container.log"
sudo screen -L -Logfile ".logs/$container.log" -dmS "$mitmp" sudo node /root/honeypots/MITM/mitm/index.js "$mitmconf"
echo "done"
