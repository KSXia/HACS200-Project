#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: ./stdin_timeout.bash [timeout]"
    exit 1
fi

timeout="$1"

while read -r -t $timeout line; do
    :
done
