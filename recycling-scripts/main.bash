#!/bin/bash

# "$1" = [profile]
    # [profile] is the unique profile name associated with an IP address
# "$2" = [container]
    # [container] is the unique container name
# "$3" = [mitmp]
    # [mitmp] is the unique MITM process name
if [[ $# -ne 3 ]]; then
    echo "usage: ./main.bash [profile] [container] [mitmp]"
    exit 1
fi

TREATMENTS=("control" "ssh" "ssl" "api")

# ignore keyboard interrupts
trap : INT

# Delete container/MITM if still running from a previous run
if lxc info "$2" &>/dev/null; then
    ./delete_container.bash "$2" "$3"
fi

while true; do
    # RANDOM is a random integer between 0 and 32767 (2^15 - 1)
    random_number=$((RANDOM))
    # modulo by the number of treatments to create a bounded index
    random_index=$((random_number % ${#TREATMENTS[@]}))
    # index into list of treatments to select a treatment
    random_treatment=${TREATMENTS[$random_index]}

    echo "random treatment selected: $random_treatment"
    ./creation.bash "$random_treatment" "$1" "$2" "$3"

    # todo!() figure out why this `sleep 10` is here
    echo "todo!() why sleep 10"
    sleep 10

    ./wait_for_attacker.bash "$2" "$3"
    if (($? == 11)); then
        exit 11
    fi

    # Make new directory if there is no directory for the current date
    date=$(date +%Y-%m-%d)
    if ! ls data/$date &>/dev/null; then
      mkdir data/$date
    fi
    log_num=$(ls data/$date | wc -l)

    ./wait_for_log.bash "$2" "$3"
    if (($? == 11)); then
        exit 11
    fi

    ./extract_data.bash "$2" "$random_treatment" "log-$2" "data/$date/mitm-$log_num.log"
    ./recycle_container.bash "$2" "$3"
done
