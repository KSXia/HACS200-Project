#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
# "$2" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 2 ]]; then
    echo "usage: ./wait_for_log.bash [container] [mitmp]"
    exit 1
fi

# saved globally because $1 inside a function is the function's own argument
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

# Check if MITM log has been completely recorded
end_of_file=0
while [[ $end_of_file -eq 0 ]]; do
  end_of_file=$(grep -c "Container's OpenSSH server closed connection" "log-$container")
  wait_or_quit 0.1
done
