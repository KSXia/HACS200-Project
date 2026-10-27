#!/bin/bash

# "$1" = [mitm log fp]
    # [mitm log fp] is the MITM log file path
# "$2" = [inactivity timeout]
    # [inactivity timeout] is how many seconds the attacker may go without typing
# Returns once the session timeout (session_timeout.bash) or the inactivity timeout
# (inactivity_timeout.bash) fires, and stops the other one. Exit status:
#   10 = session timeout
#   20 = inactivity timeout
if [[ $# -ne 2 ]]; then
    echo "usage: ./wait_timeout.bash [mitm log fp] [inactivity timeout]"
    exit 1
fi

mitml_fp="$1"
inactivity_timeout="$2"

# Each timer runs in its own process group (setsid) so everything it starts (sleep, tail,
# grep) can be killed together
setsid ./session_timeout.bash &
session_job=$!

setsid ./inactivity_timeout.bash "$mitml_fp" "$inactivity_timeout" &
inactivity_job=$!

# Runs on every exit, including when the caller kills this script, so no timer is left behind
stop_timers() {
    kill -- -"$session_job" -"$inactivity_job" 2> /dev/null
}
trap stop_timers EXIT
trap 'exit 143' TERM INT HUP

# Block until the first timer finishes
wait -n
status=$?

# A timer that failed (e.g. script not found) did not time out, so do not report a timeout
if (( status != 0 )); then
    echo "wait_timeout.bash: a timer exited with status $status" >&2
    exit 1
fi

if ! kill -0 "$session_job" 2> /dev/null; then
    exit 10
else
    exit 20
fi
