#!/bin/bash

# Check for right number of arguments, print usage text if wrong
if [[ $# -ne 2 ]]
then
  echo "[Usage]: ./main_loop.sh [number] [mitm process name]"
  exit 1
fi

lxc info cont-$1 &>/dev/null && ./recycling.sh cont-$1 $2   # Delete container/MITM if still running

CONTAINERS=("cont" "ssh" "ssl" "api")

while true
do
  RANDOM_INDEX=$((RANDOM % ${#CONTAINERS[@]}))
  SELECTED_CONTAINER=${CONTAINERS[$RANDOM_INDEX]}
  
  echo "Launching with randomized treatment: \"$SELECTED_CONTAINER\""
  
  ./creation.sh $SELECTED_CONTAINER $1 $2
  sleep 10
  
  # ---TODO---
  # NEED TO CHANGE THIS TO INSTEAD DETECT CONNECTIONS VIA MITM LOG
  past_user=`lxc exec cont-$1 -- sudo last | head -n 1`
  new_user=`lxc exec cont-$1 -- sudo last | head -n 1`

  echo "[Setup]: Setup complete, waiting for attacker to connect..."
  echo "[Input]: Type 'q' to exit process and delete container"
  
  # Check for new user
  while [[ $past_user == $new_user ]]
  do
    new_user=`lxc exec cont-$1 -- sudo last | head -n 1`
    quit=""
    read -t 0.1 -n 1 quit
    if [[ $quit == "q" ]]
    then
      echo ""
      ./recycling.sh cont-$1 $2
      break 2
    fi
    sleep 0.1
  done
  
  echo "[!] Attacker has entered the container"
  
  num_online=1
  enter_time=`date +%s`
  
  # Check if attacker has exited container
  while [[ $num_online -gt 0 || $time_elapsed < 300 ]]
  do
    # ---TODO---
    # Change this to base whether the attacker is still connected on the MITM logs
    num_online=`lxc exec cont-$1 -- who | wc -l`
    sleep 0.5
    curr_time=`date +%s`
    time_elapsed=$(( $curr_time - $enter_time ))
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
    end_of_file=`cat log-$1 | grep "Container's OpenSSH server closed connection" | wc -l`
    sleep 0.1
  done

  # Extraction and recycling
  # ./extract_data.sh log-$profile_num.txt data/$date/mitm$log_num.log
  ./recycling.sh cont-$1 $2
done
