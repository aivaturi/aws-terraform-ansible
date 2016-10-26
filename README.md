# aws-terraform-ansible

Provision a fully automated stack in AWS using Terraform and Ansible

# Provision VPC
./deploy.sh --> This will ask you for all the information it needs.

What it provisions right now:

- A full /16 with subnets for public, management, Web app and DB
- Appropriate security groups that is locked down to your egress IP. Can only SSH to bastion host from outside.
- Provision and deploy
    - bastion host
    - PKI host (Install golang, CFSSL and generate certs)
    - Three node consul cluster fully configured.

And of course, an ansible set up that is ready to use with no static hosts.

```
$ ./deploy.sh

I need few things from you to get started...

AWS Acess Key  :
AWS Secret Key :
AWS EC2 Region (e.g. us-east-1): us-east-1

VPC Name (e.g. prod) : dev
VPC DOMAIN (e.g. example.com) : myapp.dev
VPC CIDR Block (pick a /16, e.g. 10.10.0.0/16) : 10.10.0.0/16

06:49:05 PM [     info] Now, I need your egreess IP. Go to http://whatismyip.com and find out
Egress IP : 50.136.242.140

06:49:29 PM [     info] [terraform] Creating plan
Get: file:///Users/aditya/code/aws-terraform-ansible/site/vpc
Get: file:///Users/aditya/code/aws-terraform-ansible/instances/bastion
Get: file:///Users/aditya/code/aws-terraform-ansible/site/ssh
Get: file:///Users/aditya/code/aws-terraform-ansible/instances/pki
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.

module.bastion.data.template_file.userdata: Refreshing state...
module.pki.data.template_file.userdata: Refreshing state...
module.bastion.data.aws_ami.ubuntu: Refreshing state...
module.pki.data.aws_ami.ubuntu: Refreshing state...

The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Your plan was also saved to the path below. Call the "apply" subcommand
with this plan file and Terraform will exactly execute this execution
plan.

Path: dev.tfplan

+ module.pki.aws_instance.pki
    ami:                                       "ami-c8580bdf"

...<snip>...

Plan: 48 to add, 0 to change, 0 to destroy.

06:49:36 PM [    input] Is the plan acceptable? (y/n) y
06:49:38 PM [     info] [terraform] Applying the plan
module.vpc.null_resource.mgmt: Creating...
```

Currently, this is tested only on OSX.

... more documentation to follow, until then - read the source Luke!
