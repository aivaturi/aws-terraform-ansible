# Hack to essentially facilitate global vars
 
variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {}
variable "dns_domain" {}
variable "azs" {
    default = {}
}
variable "dns_zone_id" {}
variable "subnet" {}
variable "sg" {
    default = []
}
variable "sg_mgmt" {}
variable "ssh_key_file" {}
variable "bastion_host" { default = "" }