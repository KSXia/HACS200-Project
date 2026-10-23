#!/bin/bash

for file in $(ls | grep -v "create.sh")
do
  cp $file /root/honeypots/MITM/config
done
