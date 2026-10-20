#!/bin/bash

# Check for right number of arguments, print usage text if wrong
if [[ $# -ne 2 ]]
then
  echo "[Usage]: ./main_loop.sh [number] [mitm process name]"
  exit 1
fi

num="$1"
mitm="$2"

# Hard reset and exit (used by 'q' and Ctrl-C)
quit_now() {
  echo ""
  ./recycling.sh cont-$num $mitm hard
  exit 0
}

# Wait up to $1 seconds for a keypress, quit if it is 'q'
wait_or_quit() {
  local key=""
  read -r -t "$1" -n 1 key
  [[ $key == "q" ]] && quit_now
}

trap quit_now INT

lxc info cont-$num &>/dev/null && ./recycling.sh cont-$num $mitm hard   # Delete container/MITM if still running

CONTAINERS=("cont" "ssh" "ssl" "api")

while true
do
  RANDOM_INDEX=$((RANDOM % ${#CONTAINERS[@]}))
  SELECTED_CONTAINER=${CONTAINERS[$RANDOM_INDEX]}

  echo "Launching with randomized treatment: \"$SELECTED_CONTAINER\""

  ./creation.sh $SELECTED_CONTAINER $num $mitm
  sleep 10

  # ---TODO---
  # NEED TO CHANGE THIS TO INSTEAD DETECT CONNECTIONS VIA MITM LOG
  past_user=`lxc exec cont-$num -- sudo last < /dev/null | head -n 1`
  new_user=`lxc exec cont-$num -- sudo last < /dev/null | head -n 1`

  echo "[Setup]: Setup complete, waiting for attacker to connect..."
  echo "[Input]: Type 'q' to exit process and delete container"

  # Check for new user
  while [[ "$past_user" == "$new_user" ]]
  do
    new_user=`lxc exec cont-$num -- sudo last < /dev/null | head -n 1`
    wait_or_quit 0.1
  done

  echo "[!] Attacker has entered the container"

  num_online=1

  # Check if attacker has exited container
  while [[ $num_online -gt 0 ]]
  do
    # ---TODO---
    # Change this to base whether the attacker is still connected on the MITM logs
    num_online=`lxc exec cont-$num -- who < /dev/null | wc -l`
    wait_or_quit 0.5
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
    end_of_file=`grep -c "Container's OpenSSH server closed connection" log-$num`
    wait_or_quit 0.1
  done

  # Extraction and recycling (extraction must run before the soft reset)
  ./extract_data.sh log-$num data/$date/mitm$log_num.log $SELECTED_CONTAINER
  ./recycling.sh cont-$num $mitm soft
done
