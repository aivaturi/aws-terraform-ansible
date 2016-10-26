# Hack to essentially facilitate global vars

variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {}
variable "dns_domain" {}
variable "azs" {
    default = {}
}
variable "remote_ips" {
    default = []
}
variable "ssh_key_file_pub" {}
