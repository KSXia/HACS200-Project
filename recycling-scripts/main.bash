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

# Recycle the container; if that fails, delete it so creation.bash launches a fresh one
recycle_or_reset() {
    if ! ./recycle_container.bash "$container" "$mitmp"; then
        echo "recycle failed, deleting \"$container\" so the next loop starts from a fresh container"
        ./delete_container.bash "$container" "$mitmp"
    fi
}

# ignore keyboard interrupts
trap : INT

# Delete container/MITM if still running from a previous run
if lxc info "$container" &>/dev/null; then
    ./delete_container.bash "$container" "$mitmp"
fi

while true; do
    echo $(date)

    # RANDOM is a random integer between 0 and 32767 (2^15 - 1)
    random_number=$((RANDOM))
    # modulo by the number of treatments to create a bounded index
    random_index=$((random_number % ${#TREATMENTS[@]}))
    # index into list of treatments to select a treatment
    random_treatment=${TREATMENTS[$random_index]}
    echo $random_treatment > .$container-treatment.txt

    echo "random treatment selected: $random_treatment"

    logfp="../data"

    # creation.bash fails if the container's sshd never comes up; start over with a fresh container
    if ! ./creation.bash "$profile" "$container" "$mitmp" "$logfp"; then
        echo "creation failed, deleting \"$container\" and trying again"
        ./delete_container.bash "$container" "$mitmp"
        sleep 10
        continue
    fi

    end_recycle=$(date +%s)
    [[ $begin_recycle != 0 ]] && echo "Recycled in $(($end_recycle - $begin_recycle)) seconds"

    ./wait_for_attacker.bash "$container" "$mitmp" "$logfp"
    status=$?
    if ((status == 11)); then
        exit 11
    fi
    # 12: MITM got stuck locked to an attacker who never got in; nothing to extract, just recycle
    if ((status == 12)); then
        recycle_or_reset
        continue
    fi

    begin_recycle=$(date +%s)

    ./wait_for_log.bash "$container" "$mitmp" "$logfp"
    if (($? == 11)); then
        exit 11
    fi

    # Make new directory if there is no directory for the current date
    date=$(date +%Y-%m-%d)
    if ! ls ../data/$container/$date &>/dev/null; then
      mkdir ../data/$container/$date
    fi
    log_num=$(ls ../data/$container/$date | wc -l)
    output_fp="../data/$container/$date/$log_num"
    mkdir $output_fp

    ./extract_data.bash "$container" "$random_treatment" "$logfp" "$output_fp"
    recycle_or_reset
done
