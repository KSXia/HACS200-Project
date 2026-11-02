#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# Waits (up to 60 seconds) until the container's sshd accepts connections. Exits 0 once it does,
# 1 if it never does.
#
# MITM must not start before this: an attacker who logs in while sshd is still starting gets
# MITM to lock the container to their password, then their connection fails and nobody else
# can get in until the next recycle (the Oct 31 outage).
if [[ $# -ne 1 ]]; then
    echo "usage: ./wait_for_sshd.bash [container]"
    exit 1
fi

container="$1"

echo -n "waiting for container sshd.. "
for (( i = 0; i < 60; i++ )); do
    # the IP can take a moment to appear after a start, so look it up on every try
    container_ip=$(lxc list "$container" -c 4 --format csv | awk '{print $1}')
    if [[ -n "$container_ip" ]] && nc -z -w 1 "$container_ip" 22 2> /dev/null; then
        echo "done ($container_ip)"
        exit 0
    fi
    sleep 1
done
echo "timed out after 60 seconds"
exit 1
