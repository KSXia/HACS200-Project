#!/bin/bash

if [[ $# -ne 3 ]]
then
  echo "[Usage]: ./extract_data.sh [MITM log file path] [output file path] [treatment]"
  exit 1
fi

log="$1"
out="$2"
treatment="$3"

# MITM keys its login files by zero-padded container number (cont-01.txt)
log_name=$(basename "$log")
num="${log_name#log-}"
num=$(printf "%02d" "$((10#$num))")
login_file="/root/MITM_data/logins/cont-${num}.txt"

if [[ ! -f $log ]]
then
  echo "[Extraction]: Log file $log not found"
  exit 1
fi

echo "[Extraction]: Extracting and parsing data from MITM log file..."

# Date and time connected / disconnected (first auth line, last close line)
t_start=$(grep "\[LXC-Auth\]" "$log" | head -n 1 | colrm 24)
t_end=$(grep "\[LXC\] Container's OpenSSH server closed" "$log" | tail -n 1 | colrm 24)

if [[ -z $t_start || -z $t_end ]]
then
  echo "[Extraction]: Could not find connect/disconnect timestamps in $log"
  exit 1
fi

# Time spent connected (ms)
ms_start=$(date -d "$t_start" +%s%3N)
ms_end=$(date -d "$t_end" +%s%3N)

if [[ -z $ms_start || -z $ms_end ]]
then
  echo "[Extraction]: Could not parse timestamps ('$t_start' / '$t_end')"
  exit 1
fi

t_delta=$(( ms_end - ms_start ))

# Number of commands
num_cmds=$(grep -c "\[SHELL\] line from reader:" "$log")

# List of commands
if [[ $num_cmds -eq 0 ]]
then
  cmd_list="[]"
else
  cmd_list=$(grep "\[SHELL\] line from reader:" "$log" | colrm 1 60 | sed 's/,/,,/g' | awk '{sub(/\r$/,""); printf("%s\", \"", $0)} END {print ""}' | sed 's/^/["/' | sed 's/, "$/]/')
fi

# IP address
ip=$(sudo cat "$login_file" | tail -n 1 | cut -d";" -f2)

# Write everything at once so a failure above never leaves a partial record
{
  echo "$t_start"
  echo "$num_cmds"
  echo "$cmd_list"
  echo "$ip"
  echo "$t_delta"
  echo "$treatment"
} >> "$out"
