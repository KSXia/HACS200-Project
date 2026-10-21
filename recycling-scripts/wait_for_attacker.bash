#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
if [[ $# -ne 1 ]]; then
    echo "usage: ./wait_for_attacker.bash [container]"
    exit 1
fi

# Hard reset and exit (used by 'q' and Ctrl-C)
quit_now() {
  echo ""
  ./delete_container.bash "$1"
  exit 0
}

# Wait up to $1 seconds for a keypress, quit if it is 'q'
wait_or_quit() {
  local key=""
  read -r -t "$1" -n 1 key
  [[ $key == "q" ]] && quit_now
}

trap quit_now INT

# ---TODO---
# NEED TO CHANGE THIS TO INSTEAD DETECT CONNECTIONS VIA MITM LOG
past_user=`lxc exec "$1" -- sudo last < /dev/null | head -n 1`
new_user=`lxc exec "$1" -- sudo last < /dev/null | head -n 1`

# echo "[Setup]: Setup complete, waiting for attacker to connect..."
# echo "[Input]: Type 'q' to exit process and delete container"

# Check for new user
while [[ "$past_user" == "$new_user" ]]
do
  new_user=$(lxc exec "$1" -- sudo last < /dev/null | head -n 1)
  wait_or_quit 0.1
done

echo "[!] Attacker has entered the container"

num_online=1

# Check if attacker has exited container
while [[ $num_online -gt 0 ]]
do
  # ---TODO---
  # Change this to base whether the attacker is still connected on the MITM logs
  num_online=`lxc exec "$1" -- who < /dev/null | wc -l`
  wait_or_quit 0.5
done

echo "[!] Attacker has left container"
