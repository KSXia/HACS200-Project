#!/bin/bash

# [container] is the unique name of the container
# [treatment] is the name of the treatment
# [log fp] is the MITM log file path
# [output fp] is the output file path
# [leave reason fp] is the file wait_for_attacker.bash wrote the leave reason to
if [[ $# -ne 4 ]]
then
    echo "usage: ./extract_data.bash [container] [treatment] [log fp] [output fp]"
    exit 1
fi

container="$1"
treatment="$2"
log_fp="$3"
output_fp="$4"
mitm_log_fp="$log_fp/.$container.log"
leave_reason_fp="$log_fp/.$container.leave_reason"
logins_fp="$log_fp/.$container.logins"
attempts_fp="$log_fp/.$container.attempts"

mitmd_fp="/root/MITM_data/" # location of internal MITM_data logs

echo "extracting data from MITM container \"$container\" with treatment \"$treatment\":"
echo "    mitml fp \"$mitml_fp\""
echo "    output fp \"$output_fp\""

session=$(sudo tail -n 1 $mitmd_fp/logins/$container.txt | sed 's/.*;//g')
echo "    session ID is $session"
sudo cp "$mitmd_fp/sessions/$session.gz" $output_fp/session.log.gz

echo "$treatment" > "$output_fp/config"
cp "$mitm_log_fp" "$output_fp/mitm.log"
if [[ -s "$leave_reason_fp" ]]; then
    cp "$leave_reason_fp" "$output_fp/leave_reason"
else
    echo "    leave reason file \"$leave_reason_fp\" not found, recording unknown"
    echo "unknown" > "$output_fp/leave_reason"
fi

mv "$logins_fp" "$output_fp/logins.txt"
mv "$attempts_fp" "$output_fp/login_attempts.txt"

