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

echo "recycling container \"$container\""

# Stop MITM first so no attacker reaches the old (locked) MITM while the container is reset
./stop_mitm.bash "$container" "$mitmp"

# Force the stop: a clean shutdown takes about 20 seconds, and nothing on the container's disk
# needs saving because the snapshot restore below replaces it anyway
echo -n "stopping container.. "
if ! lxc stop "$container" --force > /dev/null; then
    echo "failed"
    exit 1
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
