#!/bin/bash

# [treatment] is the name of the treatment
# [profile] is the unique profile name associated with an IP address
# [container] is the unique container name
# [mitmp] is the unique MITM process name
if [[ $# -ne 4 ]]; then
    echo "usage: ./creation.bash [treatment] [profile] [container] [mitmp]"
    exit 1
fi

$treatment="$1"
$profile="$2"
$container="$3"
$mitmp="$4"

echo "creating MITM container \"$3\" with treatment \"$treatment\":"
echo "    profile \"$profile\""
echo "    MITM process name \"$mitmp\""

if lxc info "$container" &> /dev/null; then
    # container already exists
    echo "container \"$container\" already exists; skipping basic initialization"
else
    # container does not exist
    echo -n "launching container.. "
    lxc launch base-img "$container" -p "$2" 1> /dev/null
    echo "done"
    echo -n "creating base snapshot.. "
    lxc snapshot "$container" snapshot-base
    echo "done"
fi

# todo!() Change MITM configuration to be based on profile (this may also
# require making multiple jsons for each profile
echo "todo!() apply treatment"

echo -n "starting MITM process.. "
# truncate old log
: > "log-$container"
sudo screen -L -Logfile "log-$container" -dmS "$mitmp" sudo node /root/honeypots/MITM/mitm/index.js "$container"
echo "done"
