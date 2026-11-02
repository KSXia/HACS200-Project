#!/bin/bash

for file in $(ls | grep -v "create.bash")
do
  sudo cp $file /root/honeypots/MITM/config
done
