#!/bin/bash

# Check for right number of arguments, print usage text if wrong
if [[ $# -ne 4 ]]
then
  echo "[Usage]: ./main_loop.sh [container name] [profile] [mitm config file] [mitm process name]"
  exit 1
fi

./recycling.sh $1 $4   # Delete container/MITM if still running

while true
do

  ./creation.sh $1 $2 $3 $4
  sleep 3

  num_users=`lxc exec $1 -- sudo cat /etc/passwd | wc -l`
  new_users=`lxc exec $1 -- sudo cat /etc/passwd | wc -l`

  echo "[Setup]: Setup complete, waiting for attacker to connect..."
  echo "[Input]: Type 'q' to exit process and delete container"
  
  # Check for new user
  while [[ $new_users == $num_users ]]
  do
    new_users=`lxc exec $1 -- sudo cat /etc/passwd | wc -l`
    quit=""
    read -t 0.1 -n 1 quit
    if [[ $quit == "q" ]]
    then
      echo ""
      ./recycling.sh $1 $4
      break 2
    fi
    sleep 0.1
  done
  
  echo "[!] Attacker has entered the container"
  
  num_online=1
  
  # Check if attacker has exited container
  while [[ $num_online -gt 0 ]]
  do
    num_online=`lxc exec $1 -- who | wc -l`
    sleep 0.5
  done

  echo "[!] Attacker has left container"
  
  date=`date +%Y-%m-%d`
  
  # Make new directory if there is no directory for the current date
  if ! ls data/$date &>/dev/null
  then
    mkdir data/$date
  fi


  log_num=`ls data/$date | wc -l`
  end_of_file=0
  
  # Check if MITM log has been completely recorded
  while [[ $end_of_file -eq 0 ]]
  do
    end_of_file=`cat temp.txt | grep "Container's OpenSSH server closed connection" | wc -l`
    sleep 0.1
  done

  # Extraction and recycling
  ./extract_data.sh $1.txt data/$date/mitm$log_num.log
  ./recycling.sh $1 $4
done
