#!/bin/bash

# [profile] is the unique profile name associated with an IP address
# [container] is the unique container name
# [mitmp] is the unique MITM process name
if [[ $# -ne 4 ]]; then
    echo "usage: ./creation.bash [profile] [container] [mitmp] [log file path]"
    exit 1
fi

profile="$1"
container="$2"
mitmp="$3"
logfp="$4"
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
    # LXD sets the hostname to the container name on create, so override it before
    # the snapshot is taken (the snapshot keeps it across soft resets)
    echo -n "setting hostname.. "
    lxc exec "$container" -- cloud-init status --wait 1> /dev/null
    lxc exec "$container" -- bash -c "echo my-workstation > /etc/hostname && hostname my-workstation && sed -i \"s/\\b$container\\b/my-workstation/g\" /etc/hosts"
    echo "done"
    echo -n "creating base snapshot.. "
    lxc snapshot "$container" snapshot-base
    echo "done"
fi

# Never start MITM before the container's sshd is up (see wait_for_sshd.bash). Exits 1 without
# starting MITM if it does not come up, and main.bash then starts over with a fresh container.
if ! ./wait_for_sshd.bash "$container"; then
    echo "not starting MITM: \"$container\" sshd is not reachable"
    exit 1
fi

# Make sure no other MITM for this container is still running: it would keep the port, and the
# new one could not start
if ! ./stop_mitm.bash "$container" "$mitmp"; then
    echo "not starting MITM: \"$container\" MITM port is still in use"
    exit 1
fi

echo -n "starting MITM process.. "
sudo screen -dmS "$mitmp" bash -c "sudo node /root/honeypots/MITM/mitm/index.js $mitmconf 2>&1 | tee $logfp/.$container.log"
# sudo screen -L -Logfile "$logfp/.$container.logins" -dmS "$container-logins" tail -F -n 0 "/root/MITM_data/logins/$container.txt"
# sudo screen -L -Logfile "$logfp/.$container.attempts" -dmS "$container-attempts" tail -F -n 0 "/root/MITM_data/login_attempts/$container.txt"
echo "done"
