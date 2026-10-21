#!/bin/bash

# "$1" = [container]
    # [container] is the unique name of the container
# "$2" = [treatment]
    # [treatment] is the name of the treatment
# "$3" = [mitml fp]
    # [mitml fp] is the MITM log file path
# "$4" = [output fp]
    # [output fp] is the output file path
if [[ $# -ne 4 ]]
then
    echo "usage: ./extract_data.bash [container] [treatment] [mitml fp] [output fp]"
    exit 1
fi

echo "extracting data from MITM container \"$1\" with treatment \"$2\":"
echo "    mitml fp \"$3\""
echo "    output fp \"$4\""

if [[ ! -f "$3" ]]; then
    echo "mitml file not found"
    exit 1
fi

# Date and time connected / disconnected (first auth line, last close line)
t_start=$(grep "\[LXC-Auth\]" "$3" | head -n 1 | colrm 24)
t_end=$(grep "\[LXC\] Container's OpenSSH server closed" "$3" | tail -n 1 | colrm 24)

if [[ -z $t_start || -z $t_end ]]; then
  echo "could not find connect and/or disconnect timestamps in mitml fp \"$3\""
  exit 1
fi

# Time spent connected (ms)
ms_start=$(date -d "$t_start" +%s%3N)
ms_end=$(date -d "$t_end" +%s%3N)

if [[ -z $ms_start || -z $ms_end ]]
then
  echo "could not parse timestamps \"$t_start\" and/or \"$t_end\""
  exit 1
fi

t_delta=$(( ms_end - ms_start ))

# Number of commands
num_cmds=$(grep -c "\[SHELL\] line from reader:" "$3")

# List of commands
if [[ $num_cmds -eq 0 ]]; then
  cmd_list="[]"
else
  cmd_list=$(grep "\[SHELL\] line from reader:" "$3" | colrm 1 60 | sed 's/,/,,/g' | awk '{sub(/\r$/,""); printf("%s\", \"", $0)} END {print ""}' | sed 's/^/["/' | sed 's/, "$/]/')
fi

# IP address
ip=$(sudo cat "/root/MITM_data/logins/cont-$1.txt" | tail -n 1 | cut -d";" -f2)

# Write everything at once so a failure above never leaves a partial record
{
  echo "$t_start"
  echo "$num_cmds"
  echo "$cmd_list"
  echo "$ip"
  echo "$t_delta"
  echo "$treatment"
} >> "$4"
