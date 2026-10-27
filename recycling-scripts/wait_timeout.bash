#!/bin/bash

# "$1" = [mitm log fp]
    # [mitm log fp] is the MITM log file path
# "$2" = [timeout]
    # [timeout] is how many seconds the attacker may go without typing
# Returns once no keystroke has been logged for [timeout] seconds.
if [[ $# -ne 2 ]]; then
    echo "usage: ./wait_timeout.bash [mitm log fp] [timeout]"
    exit 1
fi

mitml_fp="$1"
inactivity_timeout="$2"

./session_timeout &
job1=$!

./inactivity_timeout "$mitml_fp" "$inactivity_timeout" &
job2=$!

wait -p finished_job -n $job1 $job2
