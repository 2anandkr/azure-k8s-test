function vm_ssh_args() {
  if [ -z "$1" ]; then
    VM=0
  else
    # do arithmetic with input within the arithmetic expansion operator $((...))
    VM=$(($1 - 1))
  fi
  eval echo adminuser@$(terraform output -json public_ip_linux | jq .[$VM]) 
}

export -f vm_ssh_args