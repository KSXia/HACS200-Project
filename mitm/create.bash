#!/bin/bash

for file in $(ls | grep -v "create.sh")
do
  sudo cp $file /root/honeypots/MITM/config
done
