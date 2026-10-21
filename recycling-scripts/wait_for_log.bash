#!/bin/bash

# "$1" = [container]
    # [container] is the unique container name
if [[ $# -ne 1 ]]; then
    echo "usage: ./wait_for_log.bash [container]"
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

# Check if MITM log has been completely recorded
end_of_file=0
while [[ $end_of_file -eq 0 ]]; do
  end_of_file=$(grep -c "Container's OpenSSH server closed connection" log-$1)
  wait_or_quit 0.1
done
