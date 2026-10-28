#!/bin/bash

# [container] is the unique name of the container
# [treatment] is the name of the treatment
# [mitml fp] is the MITM log file path
# [output fp] is the output file path
# [leave reason fp] is the file wait_for_attacker.bash wrote the leave reason to
if [[ $# -ne 5 ]]
then
    echo "usage: ./extract_data.bash [container] [treatment] [mitml fp] [output fp] [leave reason fp]"
    exit 1
fi

container="$1"
treatment="$2"
mitml_fp="$3"
output_fp="$4"
leave_reason_fp="$5"
mitmd_fp="/root/MITM_data/" # location of internal MITM_data logs

echo "extracting data from MITM container \"$container\" with treatment \"$treatment\":"
echo "    mitml fp \"$mitml_fp\""
echo "    output fp \"$output_fp\""

session=$(sudo tail -n 1 $mitmd_fp/logins/$container.txt | sed 's/.*;//g')
echo "    session ID is $session"
sudo cp "$mitmd_fp/sessions/$session.gz" $output_fp/session.log.gz


if [[ ! -f "$mitml_fp" ]]; then
    echo "mitml file not found"
    exit 1
fi

echo "$treatment" > "$output_fp/config"
cp "../data/.$container.log" "$output_fp/mitm.log"
if [[ -s "$leave_reason_fp" ]]; then
    cp "$leave_reason_fp" "$output_fp/leave_reason"
else
    echo "    leave reason file \"$leave_reason_fp\" not found, recording unknown"
    echo "unknown" > "$output_fp/leave_reason"
fi

# Add attempts.log
# Add logins.log
cp "/root/MITM_data/logins/$container.txt" "$output_fp/logins.log"
cp "/root/MITM_data/login_attempts/$container.txt" "$output_fp/login_attempts.log"
