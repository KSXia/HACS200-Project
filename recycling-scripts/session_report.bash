#!/bin/bash

# "$1" = [webhook url] (optional)
    # [webhook url] is the Slack incoming webhook URL. If omitted, $SLACK_WEBHOOK_URL is used,
    # then the first line of the .slack_webhook file next to this script (not committed to git)
# Counts the sessions recorded yesterday and today (data/cont-*/[date]/[number]) and posts
# the totals to Slack with wget. Set DRY_RUN=1 to print the message instead of posting it.
if [[ $# -gt 1 ]]; then
    echo "usage: ./session_report.bash [webhook url]"
    exit 1
fi

# found from the script's location so it also works from cron
script_dir="$(dirname "$(readlink -f "$0")")"
data_fp="$script_dir/../data"
webhook_fp="$script_dir/.slack_webhook"

webhook_url="${1:-$SLACK_WEBHOOK_URL}"
if [[ -z "$webhook_url" && -f "$webhook_fp" ]]; then
    webhook_url=$(head -n 1 "$webhook_fp")
fi
if [[ -z "$webhook_url" && "$DRY_RUN" != "1" ]]; then
    echo "no webhook url given (pass it as an argument, set SLACK_WEBHOOK_URL, or put it in $webhook_fp)" >&2
    exit 1
fi

if [[ ! -d "$data_fp" ]]; then
    echo "data directory \"$data_fp\" not found" >&2
    exit 1
fi

shopt -s nullglob

# "$1" = [container dir], "$2" = [date]; each session is one numbered folder
count_sessions() {
    local dir="$1/$2"
    if [[ -d "$dir" ]]; then
        find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
    else
        echo 0
    fi
}

# "$1" = [label], "$2" = [date]; prints one line with the total and a per container breakdown
day_line() {
    local label="$1" day="$2" total=0 detail="" container n
    for container in "$data_fp"/cont-*/; do
        n=$(count_sessions "${container%/}" "$day")
        total=$((total + n))
        detail+="$(basename "$container"): $n, "
    done
    echo "$label ($day): $total sessions (${detail%, })"
}

today=$(date +%Y-%m-%d)
yesterday=$(date -d yesterday +%Y-%m-%d)

# \n is written literally so it is a newline inside the JSON string
text="Honeypot session report\n$(day_line Yesterday "$yesterday")\n$(day_line Today "$today")"
payload="{\"text\": \"$text\"}"

if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "$text"
    exit 0
fi

response=$(wget -q -O - --header="Content-Type: application/json" --post-data="$payload" "$webhook_url")
status=$?
if (( status != 0 )); then
    echo "posting to Slack failed (wget exit status $status)" >&2
    exit 1
fi
echo "posted to Slack: $response"
