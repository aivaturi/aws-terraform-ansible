
provider "aws" {
    region = "${var.region}"
}

module "vpc" {
    source = "./site/vpc"
    vpc_name = "${var.vpc_name}"
    vpc_cidr_block = "${var.vpc_cidr_block}"
    azs = "${var.azs}"
    region = "${var.region}"
    dns_domain = "${var.dns_domain}"
    remote_ips = "${var.remote_ips}"
    ssh_key_file_pub = "${var.ssh_key_file}.pub"
}

module "bastion" {
    source = "./instances/bastion"
    vpc_name = "${var.vpc_name}"
    vpc_cidr_block = "${var.vpc_cidr_block}"
    azs = "${var.azs}"
    region = "${var.region}"
    dns_domain = "${var.dns_domain}"
    dns_zone_id = "${module.vpc.dns_zone_id}"
    subnet = "${element(module.vpc.snet_public, 0)}"
    sg = [ "${module.vpc.sg_remote_ip_white_list}" ]
    sg_mgmt = "${module.vpc.sg_allow_mgmt_hosts}"
    ssh_key_file = "${var.ssh_key_file}"
}

module "ssh" {
    source = "./site/ssh"
    bastion_public_ip = "${module.bastion.bastion_public_ip}"
    ip_glob = "${module.bastion.network_ip_glob}"
    ssh_key_file = "${var.ssh_key_file}"
    vpc_name = "${var.vpc_name}"
}

module "pki" {
    source = "./instances/pki"
    vpc_name = "${var.vpc_name}"
    vpc_cidr_block = "${var.vpc_cidr_block}"
    azs = "${var.azs}"
    region = "${var.region}"
    dns_domain = "${var.dns_domain}"
    dns_zone_id = "${module.vpc.dns_zone_id}"
    ssh_key_file = "${ssh_key_file}"
    bastion_public_ip = "${module.bastion.bastion_public_ip}"
    subnet = "${element(module.vpc.snet_mgmt, 1)}"
    sg = [
        "${module.vpc.sg_allow_mgmt_hosts}"
    ]
}

module "consul" {
    source = "./instances/consul"
    vpc_name = "${var.vpc_name}"
    vpc_cidr_block = "${var.vpc_cidr_block}"
    azs = "${var.azs}"
    region = "${var.region}"
    dns_domain = "${var.dns_domain}"
    dns_zone_id = "${module.vpc.dns_zone_id}"
    ssh_key_file = "${ssh_key_file}"
    bastion_public_ip = "${module.bastion.bastion_public_ip}"
    subnets = [
        "${element(module.vpc.snet_mgmt, 0)}",
        "${element(module.vpc.snet_mgmt, 1)}",
        "${element(module.vpc.snet_mgmt, 0)}"
    ]
    sg = [
        "${module.vpc.sg_allow_mgmt_hosts}",
        "${module.vpc.sg_allow_access_to_consul}"
    ]
}
