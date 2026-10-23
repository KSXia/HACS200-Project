#!/bin/bash

echo -n "Update MITM config files? y/n"
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating MITM config files... "
  ./mitm/create.bash
  echo "done"
fi

echo -n "Update iptables rules? y/n"
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating iptables rules... "
  ./ipconf/create.bash
  echo "done"
fi

echo -n "Update apply_treatment.bash? y/n"
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating apply_treatment.bash... "
  ./recycling-scripts/create.bash
  echo "done"
fi

echo -n "Update profiles? y/n"
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating profiles... "
  ./profiles/create.bash
  echo "done"
fi

echo -n "Update base image? y/n"
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating base image... "
  ./img-creation-scripts/create.bash
  echo "done"
fi
