#!/bin/bash

# Check for right number of arguments, print usage text if wrong
if [[ $# -ne 3 ]]
then
  echo "[Usage]: ./main_loop.sh [container name] [profile] [mitm config file] [mitm process name]"
  exit 1
fi

./recycling.sh $1 $3   # Delete container/MITM if still running

CONTAINERS=("cont-cont" "ssh-cont" "ssl-cont" "api-cont")

while true
do
  RANDOM_INDEX=$((RANDOM \%${#CONTAINERS[@]}))
  SELECTED_CONTAINER=${CONTAINERS[$RANDOM_INDEX]}
  
  echo "Launching with randomized profile $SELECTED_CONTAINER"
  
  ./creation.sh $1 $SELECTED_CONTAINER $2 $3
  sleep 3

  # WILL BE CHANGING THIS TO INSTEAD DETECT CONNECTIONS VIA MITM LOG
  past_user=`lxc exec $1 -- sudo last | head -n 1`
  new_user=`lxc exec $1 -- sudo last | head -n 1`

  echo "[Setup]: Setup complete, waiting for attacker to connect..."
  echo "[Input]: Type 'q' to exit process and delete container"
  
  # Check for new user
  while [[ $past_user == $new_user ]]
  do
    new_user=`lxc exec $1 -- sudo last | head -n 1`
    quit=""
    read -t 0.1 -n 1 quit
    if [[ $quit == "q" ]]
    then
      echo ""
      ./recycling.sh $1 $3
      break 2
    fi
    sleep 0.1
  done
  
  echo "[!] Attacker has entered the container"
  
  num_online=1
  enter_time=`date +%s`
  
  # Check if attacker has exited container
  while [[ $num_online -gt 0 && $time_elapsed < 300]]
  do
    num_online=`lxc exec $1 -- who | wc -l`
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
    end_of_file=`cat temp.txt | grep "Container's OpenSSH server closed connection" | wc -l`
    sleep 0.1
  done

  # Extraction and recycling
  ./extract_data.sh $1.txt data/$date/mitm$log_num.log
  ./recycling.sh $1 $3
done
