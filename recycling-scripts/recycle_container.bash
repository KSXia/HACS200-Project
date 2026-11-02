#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./recycle_container.bash [container] [mitmp]"
    exit 1
fi

container="$1"
mitmp="$2"

echo "recyling container \"$container\""
echo -n "stopping container.. "
lxc stop "$container" > /dev/null
echo "done"
echo -n "restoring container to base snapshot.. "
lxc restore "$container" "snapshot-base" > /dev/null
echo "done"
echo -n "starting container.. "
lxc start "$container" > /dev/null
echo "done"
echo -n "stopping mitmp.. "
sudo screen -S "$mitmp" -X quit > /dev/null
# sudo screen -S "$container-logins" -X quit
# sudo screen -S "$container-attempts" -X quit
echo "done"

CONTAINER_IP=$(lxc list $container -c 4 --format csv | awk '{print $1}')
echo "$CONTAINER_IP"

until nc -zvw1 "$CONTAINER_IP" 22; do
    echo "waiting for 22"
    sleep 2
done
echo "22 open"
