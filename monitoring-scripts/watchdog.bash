#!/bin/bash

# Checks every honeypot container and alerts Slack (through slack_notify.bash) when one is broken.
# Meant to run from root's crontab every 5 minutes, e.g.
#   */5 * * * * /home/aces/production/monitoring-scripts/watchdog.bash >> /home/aces/production/monitoring-scripts/watchdog.log 2>&1
#
# Problems it looks for, per container:
#   - its main.bash loop is not running                        (alert only: needs a person)
#   - its loop has not made progress for HEARTBEAT_LIMIT       (alert only: needs a person)
#   - MITM is not listening on its port                        (alert + ask the loop to recycle)
#   - attempts keep arriving but nobody logged in for STUCK_LIMIT (alert + ask the loop to recycle)
# A problem must be seen on two runs in a row before it is acted on, so a normal recycle (when
# MITM is briefly down) does not trigger it. Each problem is reported once, then again when fixed.

HEARTBEAT_LIMIT=$(( 10 * 60 ))  # seconds without progress before the loop counts as hung
STUCK_LIMIT=$(( 30 * 60 ))      # seconds with attempts but no login before the container counts as stuck
STUCK_MIN_ATTEMPTS=10           # attempts needed in that window (a quiet honeypot is not stuck)

script_dir="$(dirname "$(readlink -f "$0")")"
repo_fp="$script_dir/.."
data_fp="$repo_fp/data"
mitmd_fp="${MITM_DATA:-/root/MITM_data}"

now=$(date +%s)

# "$1" = [file]; seconds since the file was last modified (huge if it does not exist)
age() {
    if [[ -e "$1" ]]; then
        echo $(( now - $(stat -c %Y "$1") ))
    else
        echo 999999999
    fi
}

# "$1" = [container]; prints "action|description" for the first problem found, nothing if healthy
check() {
    local container="$1" num="${1#cont-}" port attempts cutoff

    if ! pgrep -f "main\.(bash|debug) $num( |\$)" > /dev/null; then
        echo "alert|its main.bash loop is not running"
        return
    fi

    if (( $(age "$data_fp/.$container.heartbeat") > HEARTBEAT_LIMIT )); then
        echo "alert|its main.bash loop has made no progress for over $(( HEARTBEAT_LIMIT / 60 )) minutes (hung?)"
        return
    fi

    port=$(grep -o "listenPort: *[0-9]*" "$repo_fp/mitm/$container.js" 2> /dev/null | grep -o "[0-9]*$")
    port=${port:-$(( 10000 + 10#$num ))}
    if [[ -z "$(ss -ltnH "sport = :$port")" ]]; then
        echo "reset|MITM is not listening on port $port"
        return
    fi

    # the logins file is only written when someone logs in (or reset when a session is saved)
    if (( $(age "$mitmd_fp/logins/$container.txt") > STUCK_LIMIT )); then
        cutoff=$(date -u -d "@$(( now - STUCK_LIMIT ))" '+%Y-%m-%d %H:%M:%S')
        attempts=$(awk -F';' -v t="$cutoff" '$1 >= t' "$mitmd_fp/login_attempts/$container.txt" 2> /dev/null | wc -l)
        if (( attempts >= STUCK_MIN_ATTEMPTS )); then
            echo "reset|$attempts login attempts in the last $(( STUCK_LIMIT / 60 )) minutes but nobody got in (stuck?)"
            return
        fi
    fi
}

shopt -s nullglob
for container_dir in "$data_fp"/cont-*/; do
    container=$(basename "$container_dir")
    state_fp="$data_fp/.$container.watchdog"   # "action|description|alerted" from the last run

    problem=$(check "$container")
    previous=""
    alerted=0
    if [[ -f "$state_fp" ]]; then
        IFS='|' read -r prev_action prev_desc alerted < "$state_fp"
        previous="$prev_action|$prev_desc"
    fi

    if [[ -z "$problem" ]]; then
        if [[ "$alerted" == "1" ]]; then
            "$script_dir/slack_notify.bash" "[watchdog] $container is healthy again (was: $prev_desc)"
        fi
        rm -f "$state_fp"
        continue
    fi

    action="${problem%%|*}"
    desc="${problem#*|}"
    echo "$(date -u '+%F %T') $container: $desc"

    if [[ "$problem" != "$previous" ]]; then
        # first sighting: wait for the next run to confirm it
        echo "$problem|0" > "$state_fp"
        continue
    fi

    # confirmed on two runs in a row
    if [[ "$action" == "reset" ]]; then
        # wait_for_attacker.bash sees this file and makes main.bash recycle the container
        touch "$data_fp/.$container.reset"
    fi
    if [[ "$alerted" != "1" ]]; then
        what="Alerting only; someone needs to look at it."
        [[ "$action" == "reset" ]] && what="Asked its loop to recycle the container."
        "$script_dir/slack_notify.bash" "[watchdog] $container: $desc. $what"
        echo "$problem|1" > "$state_fp"
    fi
done
