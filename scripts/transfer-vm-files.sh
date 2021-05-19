#!/usr/bin/env bash

# Get Relative Path
THIS_DIR=$(dirname "$0")
source $THIS_DIR/utility_functions.sh

if [ -z "$1" ]; then
  VM=0
else
  VM=$1
fi

# rsync --verbose  --archive --checksum $THIS_DIR/vm-files/ $(get_vm_ssh_args $VM):~/vm-files
rsync --verbose  --archive --checksum --delete -e "ssh $(ssh_options)" $THIS_DIR/../vm-files/ $(get_vm_ssh_args $VM):~/vm-files
