#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./wait_for_attacker.bash [container] [mitmp]"
    exit 1
fi

container="$1"
mitmp="$2"

# Hard reset and exit (used by 'q' and Ctrl-C); exit 11 tells main.bash to stop
quit_now() {
  echo ""
  ./delete_container.bash "$container" "$mitmp"
  exit 11
}

# Wait up to $1 seconds for a keypress, quit if it is 'q'
wait_or_quit() {
  local key=""
  read -r -t "$1" -n 1 key
  [[ $key == "q" ]] && quit_now
}

trap quit_now INT

echo "[Setup]: Setup complete, waiting for attacker to connect..."
echo "[Input]: Type 'q' to exit process and delete container"

# Check for new user
connected=0
while [[ "$connected" == "0"  ]]
do
  connected=$(cat .logs/$container.log | grep "Attacker authenticated and is inside container" | wc -l)
  wait_or_quit 0.1
done

echo "[!] Attacker has entered the container"

left=0

# Check if attacker has exited container
while [[ "$left" == "0" ]]
do
  left=$(cat .logs/$container.log | grep "Attacker closed connection" | wc -l)
  wait_or_quit 0.1
done

echo "[!] Attacker has left container"
