#!/usr/bin/env bash

max_attempts="30"
sleep_secs="30"
ssh_cfg="/tmp/terraform_ansible_ssh.cfg"

bastion_ip=$1
ip_list=$2
ARR=(${ip_list//,/ })

for ip in ${ARR[@]}; do
    echo "Attempting to SSH to instance $ip..."
    i="0"
    while [ $i -lt $max_attempts ]
    do
      echo ssh -F $ssh_cfg ubuntu@${bastion_ip} 'nc -zw3 $ip 22'
      ssh -F $ssh_cfg ubuntu@${bastion_ip} "nc -zw3 $ip 22"
      case $? in
        (0) echo "Host is up"; break ;;
        (*) echo "Host SSH server not ready yet, waiting ${sleep_secs} seconds..." ;;
      esac
      sleep $sleep_secs
      i=$[$i+1]
    done
done
