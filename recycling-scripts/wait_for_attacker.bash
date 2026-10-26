#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
# "$3" = [logfp]
    # [logfp] is the log file path
if [[ $# -ne 3 ]]; then
    echo "usage: ./wait_for_attacker.bash [container] [mitmp] [logfp]"
    exit 1
fi

container="$1"
mitmp="$2"
logfp="$3"

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
  connected=$(cat "$logfp/mitm.log" | grep "Attacker authenticated and is inside container" | wc -l)
  wait_or_quit 0.1
done

echo "[!] Attacker has entered the container"

left=0
time_entered=$(date +%s)

# Check if attacker has exited container
while [[ "$left" == "0" ]]
do
  time_now=$(date +%s)
  time_elapsed=$(( $time_now - $time_entered ))
  if [[ $time_elapsed -gt 3 ]]; then
    lxc exec $container -- sudo systemctl stop sshd
    lxc exec $container -- sudo pkill sshd
    echo "[!] Timeout occurred, kicking out attacker"
    break
  fi
  left=$(cat "$logfp/mitm.log" | grep "Attacker closed connection" | wc -l)
  wait_or_quit 0.1
done

echo "[!] Attacker has left container"
