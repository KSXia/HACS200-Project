#!/bin/bash

echo -n "Update MITM config files? (y/n): "
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating MITM config files... "
  cd mitm
  ./create.bash
  cd ..
  echo "done"
fi

echo -n "Update iptables rules? (y/n): "
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating iptables rules... "
  cd ipconf
  ./create.bash
  cd ..
  echo "done"
fi

echo -n "Update apply_treatment.bash? (y/n): "
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating apply_treatment.bash... "
  cd recycling-scripts
  ./create.bash
  cd ..
  echo "done"
fi

echo -n "Update profiles? (y/n): "
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating profiles... "
  cd profiles
  ./create.bash
  cd ..
  echo "done"
fi

echo -n "Update base image? (y/n): "
read input
if [[ "$input" == "y" ]]; then
  echo -n "Updating base image... "
  cd img-creation-scripts
  ./create.bash
  cd ..
  echo "done"
fi
