#!/usr/bin/env bash

max_attempts="30"  
sleep_secs="30"
ssh_cfg="/tmp/terraform_ansible_ssh.cfg"

bastion_ip=$1
port=22
nc_cmd="nc -zw5 $bastion_ip $port"
if [[ "$OSTYPE" == "darwin"* ]]; then
    nc_cmd="nc -zG5 $bastion_ip $port"
fi

echo "Attempting to SSH to Bastion server..."  
i="0"

while [ $i -lt $max_attempts ]
do  
  eval ${nc_cmd}
  case $? in
    (0) echo "Bastion is up"; break ;;
    (*) echo "Bastion SSH server not ready yet, waiting ${sleep_secs} seconds..." ;;
  esac
  sleep $sleep_secs
  i=$[$i+1]
done  
