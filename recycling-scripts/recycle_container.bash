#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
# Exits non-zero if the container could not be reset or its sshd did not come up;
# main.bash then deletes the container so the next loop starts from a fresh one.
if [[ $# -ne 2 ]]; then
    echo "usage: ./recycle_container.bash [container] [mitmp]"
    exit 1
fi

container="$1"
mitmp="$2"

echo "recyling container \"$container\""

# Stop MITM first so no attacker reaches the old (locked) MITM while the container is reset
echo -n "stopping mitmp.. "
sudo screen -S "$mitmp" -X quit > /dev/null
# sudo screen -S "$container-logins" -X quit
# sudo screen -S "$container-attempts" -X quit
echo "done"

# lxc stop waits forever by default, so force the stop if it takes more than 30 seconds
echo -n "stopping container.. "
if ! lxc stop "$container" --timeout 30 > /dev/null 2>&1; then
    echo -n "timed out, forcing.. "
    if ! lxc stop "$container" --force > /dev/null; then
        echo "failed"
        exit 1
    fi
fi
echo "done"

echo -n "restoring container to base snapshot.. "
if ! lxc restore "$container" "snapshot-base" > /dev/null; then
    echo "failed"
    exit 1
fi
echo "done"

echo -n "starting container.. "
if ! lxc start "$container" > /dev/null; then
    echo "failed"
    exit 1
fi
echo "done"

# a container whose sshd never comes up counts as a failed recycle
./wait_for_sshd.bash "$container"
