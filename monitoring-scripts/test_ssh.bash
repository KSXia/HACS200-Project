#!/bin/bash

# Checks that a honeypot's public IP accepts SSH connections (this also tests the iptables
# forwarding, which watchdog.bash does not) and posts to Slack if it does not.
#
# Each recycle closes the port for up to a minute or two, so the port has to stay closed for
# DOWN_LIMIT seconds before an alert is sent. Each outage is reported once, then once more when
# the port accepts connections again.
#
# [webhook url] is optional; without it slack_notify.bash's webhook is used
# (SLACK_WEBHOOK_URL or recycling-scripts/.slack_webhook).
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: test_ssh.bash [container number] [IP] [webhook url]"
  exit 1
fi

NUM="$1"
IP="$2"
PORT="22"
[[ -n "$3" ]] && export SLACK_WEBHOOK_URL="$3"

DOWN_LIMIT=${DOWN_LIMIT:-180}      # seconds the port must stay closed before alerting
CHECK_INTERVAL=${CHECK_INTERVAL:-10}

script_dir="$(dirname "$(readlink -f "$0")")"
down_fp="/tmp/test_ssh-$NUM.down"  # exists while an outage alert is out

# a check can take up to DOWN_LIMIT seconds, so only run one per container at a time
exec 9> "/tmp/test_ssh-$NUM.lock"
flock -n 9 || exit 0

log() {
  echo "[$(date +"%Y-%m-%d-%T")] $1" >> test_ssh-$NUM.log
}

# Connects to the port and exits instantly (-z) with a 1-second timeout (-w 1); keeps retrying
# until it connects or DOWN_LIMIT seconds have passed
start=$SECONDS
until nc -z -w 1 "$IP" "$PORT"; do
  if (( SECONDS - start >= DOWN_LIMIT )); then
    text="ALERT!! cont-$NUM ($IP) has not accepted SSH connections for $DOWN_LIMIT seconds, please remediate IMMEDIATELY"
    log "$text"
    if [[ ! -f "$down_fp" ]]; then
      "$script_dir/slack_notify.bash" "$text" && touch "$down_fp"
    fi
    exit 1
  fi
  sleep "$CHECK_INTERVAL"
done

log "SSH port is open, connection made and dropped before auth."
if [[ -f "$down_fp" ]]; then
  "$script_dir/slack_notify.bash" "cont-$NUM ($IP) accepts SSH connections again" && rm -f "$down_fp"
fi
