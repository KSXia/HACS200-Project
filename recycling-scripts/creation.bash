#!/bin/bash

# "$1" = [treatment]
    # [treatment] is the name of the treatment
# "$2" = [profile]
    # [profile] is the unique profile name associated with an IP address
# "$3" = [container]
    # [container] is the unique container name
# "$4" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 4 ]]; then
    echo "usage: ./creation.bash [treatment] [profile] [container] [mitmp]"
    exit 1
fi

echo "creating MITM container \"$3\" with treatment \"$1\":"
echo "    profile \"$2\""
echo "    MITM process name \"$4\""

if lxc info "$3" &> /dev/null; then
    # container already exists
    echo "container \"$3\" already exists; skipping basic initialization"
else
    # container does not exist
    echo -n "launching container.. "
    lxc launch base-img "$3" -p "$2" 1> /dev/null
    echo "done"
    echo -n "creating base snapshot.. "
    lxc snapshot "$3" snapshot-base
    echo "done"
fi

# todo!() Change MITM configuration to be based on profile (this may also
# require making multiple jsons for each profile
echo "todo!() apply treatment"

echo -n "starting MITM process.. "
# truncate old log
: > "log-$3"
sudo screen -L -Logfile "log-$3" -dmS "$4" sudo node /root/honeypots/MITM/mitm/index.js "$3"
echo "done"
