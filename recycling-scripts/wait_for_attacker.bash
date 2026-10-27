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

# seconds the attacker may go without typing before being kicked
IDLE_LIMIT=${IDLE_LIMIT:-60}

# Stop the timeout timers; wait_timeout.bash kills everything it started when it is killed
timeout_job=""
stop_timeout() {
  [[ -n "$timeout_job" ]] && kill "$timeout_job" 2> /dev/null
  timeout_job=""
}

# Hard reset and exit (used by 'q' and Ctrl-C); exit 11 tells main.bash to stop
quit_now() {
  echo ""
  stop_timeout
  ./delete_container.bash "$container" "$mitmp"
  exit 11
}

# Wait up to $1 seconds for a keypress, quit if it is 'q'
wait_or_quit() {
  local key=""
  read -r -t "$1" -n 1 key
  [[ $key == "q" ]] && quit_now
}

# Why the attacker left, copied into the session folder by extract_data.bash.
# Values: "attacker left", "idle timeout", "session timeout"
leave_reason_fp="$logfp/.$container.leave_reason"
rm -f "$leave_reason_fp"
record_leave_reason() {
  echo "$1" > "$leave_reason_fp"
}

trap quit_now INT

echo "[Setup]: Setup complete, waiting for attacker to connect..."
echo "[Input]: Type 'q' to exit process and delete container"

# Check for new user
connected=0
while [[ "$connected" == "0"  ]]
do
  connected=$(cat "$logfp/.$container.log" | grep "Attacker authenticated and is inside container" | wc -l)
  wait_or_quit 0.1
done

echo "[!] Attacker has entered the container"

left=0

# wait_timeout.bash exits when the session limit (session_timeout.bash) or the inactivity
# limit passes: status 10 for the session limit, 20 for inactivity
./wait_timeout.bash "$logfp/.$container.log" "$IDLE_LIMIT" &
timeout_job=$!

# Check if attacker has exited container
while [[ "$left" == "0" ]]
do
  if [[ -n "$timeout_job" ]] && ! kill -0 "$timeout_job" 2> /dev/null; then
    wait "$timeout_job"
    case $? in
      10) timeout_reason="session timeout" ;;
      20) timeout_reason="idle timeout" ;;
      *)  timeout_reason="" ;;
    esac
    timeout_job=""
    if [[ -n "$timeout_reason" ]]; then
      lxc exec $container -- sudo systemctl stop sshd
      lxc exec $container -- sudo pkill sshd
      echo "[!] Timeout occurred ($timeout_reason), kicking out attacker"
      record_leave_reason "$timeout_reason"
      break
    fi
    echo "[!] Warning: timeout timer stopped unexpectedly, attacker will not be kicked automatically"
  fi
  left=$(cat "$logfp/.$container.log" | grep "Attacker closed connection" | wc -l)
  if [[ "$left" != "0" ]]; then
    record_leave_reason "attacker left"
  fi
  wait_or_quit 0.1
done

stop_timeout

echo "[!] Attacker has left container"
