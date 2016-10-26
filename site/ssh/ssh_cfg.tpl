Host ${bastion_public_ip}
  IdentityFile ${ssh_key_file}
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  User ubuntu

Host ${ip_glob}
  IdentityFile ${ssh_key_file}
  ProxyCommand ssh -i ${ssh_key_file} ubuntu@${bastion_public_ip} nc -w 60 %h %p
  UserKnownHostsFile /dev/null
  IdentitiesOnly  yes
  ControlMaster   auto
  ControlPath     /tmp/.ssh/mux-%r@%h:%p
  ControlPersist  15m
  StrictHostKeyChecking no
  User ubuntu
