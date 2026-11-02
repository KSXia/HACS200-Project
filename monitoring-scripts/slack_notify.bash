#!/bin/bash

# "$1" = [message]
    # [message] is the text to post
# Posts a message to the same Slack webhook session_report.bash uses: $SLACK_WEBHOOK_URL if set,
# otherwise the first line of recycling-scripts/.slack_webhook (not committed to git).
# Set DRY_RUN=1 to print the message instead of posting it.
if [[ $# -ne 1 ]]; then
    echo "usage: ./slack_notify.bash [message]"
    exit 1
fi

message="$1"

script_dir="$(dirname "$(readlink -f "$0")")"
webhook_fp="$script_dir/../recycling-scripts/.slack_webhook"

if [[ "$DRY_RUN" == "1" ]]; then
    echo "[slack dry run] $message"
    exit 0
fi

webhook_url="$SLACK_WEBHOOK_URL"
if [[ -z "$webhook_url" && -f "$webhook_fp" ]]; then
    webhook_url=$(head -n 1 "$webhook_fp")
fi
if [[ -z "$webhook_url" ]]; then
    echo "no webhook url (set SLACK_WEBHOOK_URL or put it in $webhook_fp)" >&2
    exit 1
fi

# escape backslashes, double quotes and newlines so the message is a valid JSON string
text=$(printf '%s' "$message" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s%s", (NR > 1 ? "\\n" : ""), $0}')
payload="{\"text\": \"$text\"}"

if ! wget -q -O - --header="Content-Type: application/json" --post-data="$payload" "$webhook_url" > /dev/null; then
    echo "posting to Slack failed" >&2
    exit 1
fi
