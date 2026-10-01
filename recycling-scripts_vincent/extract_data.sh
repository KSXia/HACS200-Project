#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo "[Usage]: ./extract_data.sh [MITM log file path] [output files path]"
  exit 1
fi

echo "[Extraction]: Extracting and parsing data from MITM log file..."

# Record date and time connected
t_start=`cat $1 | grep "\[LXC-Auth\]" | colrm 24`
echo $t_start >> $2

# Record number of commands
cat $1 | grep "\[SHELL\] line from reader:" | colrm 1 60 | wc -l >> $2

# Record a list of commands
cat $1 | grep "\[SHELL\] line from reader:" | colrm 1 60 | sed 's/,/,,/g' | awk '{sub(/\r$/,""); printf("%s\", \"", $0)} END {print ""}' | sed 's/^/[\"/' | sed 's/, \"$/]/' >> $2

# Record IP address
sudo cat /root/MITM_data/logins/$1 | tail -1 | cut -d";" -f2 >> $2

# Record time spent connected (ms)
t_end=`cat $1 | grep "\[LXC\] Container's OpenSSH server closed" | colrm 24`

epoch_start=`date -d "$t_start" +%s`
ms_start=`echo $t_start | colrm 1 20 | sed 's/^0*//'`

epoch_end=`date -d "$t_end" +%s`
ms_end=`echo $t_end | colrm 1 20 | sed 's/^0*//'`

t_delta=$(( ($epoch_end - $epoch_start) * 1000 + ($ms_end - $ms_start) ))

echo $t_delta >> $2
