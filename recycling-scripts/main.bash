#!/bin/bash

# "$1" = [number]
    # [number] The unique number that identifies the profile, container, mitm process, and log file names
if [[ $# -ne 1 ]]; then
    echo "usage: ./main.bash [number]"
    exit 1
fi

profile="profile-$1"
container="cont-$1"
mitmp="mitm-$1"

TREATMENTS=("control" "ssh" "ssl" "api")
begin_recycle=0

# ignore keyboard interrupts
trap : INT

# Delete container/MITM if still running from a previous run
if lxc info "$container" &>/dev/null; then
    ./delete_container.bash "$container" "$mitmp"
fi

while true; do
    # RANDOM is a random integer between 0 and 32767 (2^15 - 1)
    random_number=$((RANDOM))
    # modulo by the number of treatments to create a bounded index
    random_index=$((random_number % ${#TREATMENTS[@]}))
    # index into list of treatments to select a treatment
    random_treatment=${TREATMENTS[$random_index]}
    echo $random_treatment > .treatment.txt

    echo "random treatment selected: $random_treatment"

    # Make new directory if there is no directory for the current date
    date=$(date +%Y-%m-%d)
    if ! ls data/$container/$date &>/dev/null; then
      mkdir data/$container/$date
    fi
    log_num=$(ls data/$container/$date | wc -l)
    logfp="data/$container/$date/$log_num"
    mkdir "$logfp"

    ./creation.bash "$profile" "$container" "$mitmp" "$logfp"

    end_recycle=$(date +%s)
    [[ $begin_recycle != 0 ]] && echo "Recycled in $(($end_recycle - $begin_recycle)) seconds"

    ./wait_for_attacker.bash "$container" "$mitmp" "$logfp"
    if (($? == 11)); then
        exit 11
    fi

    begin_recycle=$(date +%s)

    ./wait_for_log.bash "$container" "$mitmp" "$logfp"
    if (($? == 11)); then
        exit 11
    fi

    ./extract_data.bash "$container" "$random_treatment" "$logfp/mitm.log" "$logfp"
    ./recycle_container.bash "$container" "$mitmp"
done
