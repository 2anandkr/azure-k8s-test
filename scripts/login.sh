#!/usr/bin/env bash

# Get Relative Path
THIS_DIR=$(dirname "$0")

source $THIS_DIR/utility_functions.sh

if [ -z "$1" ]; then
  VM=0
else
  VM=$1
fi

ssh $(get_vm_ssh_args $VM)