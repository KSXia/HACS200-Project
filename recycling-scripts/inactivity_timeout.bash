#!/bin/bash

# "$1" = [mitm log fp]
    # [mitm log fp] is the MITM log file path
# "$2" = [timeout]
    # [timeout] is how many seconds the attacker may go without typing
# Returns once no keystroke has been logged for [timeout] seconds.
if [[ $# -ne 2 ]]; then
    echo "usage: ./inactivity_timeout.bash [mitm log fp] [timeout]"
    exit 1
fi

mitml_fp="$1"
timeout="$2"

# tail --pid ends the tail shortly after this script returns, which would otherwise leave
# tail and grep running (tail -F never ends by itself)
tail -n 0 -F --pid=$$ "$mitml_fp" 2> /dev/null \
    | grep --line-buffered "Attacker Keystroke" \
    | ./stdin_timeout.bash "$timeout" 