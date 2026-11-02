#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
# Stops every MITM for this container, then waits (up to 15 seconds) for its port to be free.
# Exits 1 if the port is still in use.
#
# "screen -S [mitmp] -X quit" refuses to act when two sessions share a name, so a duplicate MITM
# session (e.g. left over after a crash) could never be stopped and would keep the port, possibly
# while locked to an old attacker. This stops each session by its full id instead, plus any MITM
# process for this container that is running outside screen.
if [[ $# -ne 2 ]]; then
    echo "usage: ./stop_mitm.bash [container] [mitmp]"
    exit 1
fi

container="$1"
mitmp="$2"

script_dir="$(dirname "$(readlink -f "$0")")"
port=$(grep -o "listenPort: *[0-9]*" "$script_dir/../mitm/$container.js" 2> /dev/null | grep -o "[0-9]*$")
port=${port:-$(( 10000 + 10#${container#cont-} ))}

echo -n "stopping mitmp.. "
# screen -ls lists sessions as "<pid>.<name>"
for session in $(sudo screen -ls | awk -v name="$mitmp" '{ split($1, id, "."); if (id[2] == name) print $1 }'); do
    sudo screen -S "$session" -X quit > /dev/null
done
# a MITM that outlived its screen session ([i] keeps pkill from matching its own command line)
sudo pkill -f "mitm/[i]ndex.js $container.js" > /dev/null 2>&1

for (( i = 0; i < 15; i++ )); do
    if [[ -z "$(ss -ltnH "sport = :$port")" ]]; then
        echo "done"
        exit 0
    fi
    sleep 1
done
echo "port $port is still in use"
exit 1
