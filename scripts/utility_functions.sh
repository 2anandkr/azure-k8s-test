function get_user() {
  echo "adminuser"
}

function ssh_options() {
  echo " -i ./tester_key" 
}
export -f ssh_options

function get_vm_ssh_args() {
  if [ -z "$1" ]; then
    VM=0
  else
    VM=$(($1 - 1))
  fi
  eval echo "$(ssh_options) $(get_user)@$(terraform output -json public_ip_linux | jq .[$VM])"
}
export -f get_vm_ssh_args