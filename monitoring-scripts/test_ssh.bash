#!/bin/bash

if [[ $# -ne 3 ]]; then
  echo "Usage: test_ssh.bash [container number] [IP] [webhook url]"
  exit 1
fi

NUM="$1"
IP="$2"
webhook_url="$3"
PORT="22"

date=$(date +"%Y-%m-%d-%T")
# Connects to the port and exits instantly (-z) with a 1-second timeout (-w 1)
if nc -z -w 1 "$IP" "$PORT"; then
  echo "[$date] SSH port is open, connection made and dropped before auth." >> test_ssh-$NUM.log
else
  text="ALERT!! cont-$NUM is not accessible by SSH, please remediate IMMEDIATELY"
  echo "[$date] $text" >> test_ssh-$NUM.log
  payload="{\"text\": \"$text\"}"
  response=$(wget -q -O - --header="Content-Type: application/json" --post-data="$payload" "$webhook_url")
fi
