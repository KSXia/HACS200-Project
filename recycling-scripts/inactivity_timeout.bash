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

# The keystroke feed is a process substitution instead of a pipe: bash waits for every command
# in a pipe, and tail -F never ends, so this script would never return when stdin_timeout does.
# tail --pid ends the tail shortly after this script returns.
./stdin_timeout.bash "$timeout" < <(
    tail -n 0 -F --pid=$$ "$mitml_fp" 2> /dev/null \
        | grep --line-buffered "Attacker Keystroke"
)
