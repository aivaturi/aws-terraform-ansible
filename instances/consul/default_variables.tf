# Hack to essentially facilitate global vars
 
variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {}
variable "dns_domain" {}
variable "azs" {
    default = {}
}
variable "dns_zone_id" {}
variable "subnets" {
    default = []
}
variable "sg" {
    default = []
}
variable "ssh_key_file" {}
variable "bastion_public_ip" {}
