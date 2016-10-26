
resource "aws_vpc" "main" {
    cidr_block           = "${var.vpc_cidr_block}"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
        "Name" = "${var.vpc_name}"
    }
}

## This is where Firewall/IDP should reside
resource "aws_subnet" "public" {
    vpc_id            = "${aws_vpc.main.id}"
    count             = "${length(split(",", lookup(var.azs, var.region)))}"
    cidr_block        = "${lookup(null_resource.public.triggers, count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"
    map_public_ip_on_launch = false

    tags {
        "Name" = "${var.vpc_name} public-${element(split(",", lookup(var.azs, var.region)), count.index)}"
    }
}

output "snet_public" {
    value = ["${aws_subnet.public.*.id}"]
}

## Management subnet (bastion, Jenkins, Nagios etc)
resource "aws_subnet" "mgmt" {
    vpc_id            = "${aws_vpc.main.id}"
    count             = "${length(split(",", lookup(var.azs, var.region)))}"
    cidr_block        = "${lookup(null_resource.mgmt.triggers, count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"
    map_public_ip_on_launch = false

    tags {
        "Name" = "${var.vpc_name} mgmt-${element(split(",", lookup(var.azs, var.region)), count.index)}"
    }
}

output "snet_mgmt" {
    value = ["${aws_subnet.mgmt.*.id}"]
}

## App servers (Ruby on Rails, Django etc)
resource "aws_subnet" "webapp_1" {
    vpc_id            = "${aws_vpc.main.id}"
    count             = "${length(split(",", lookup(var.azs, var.region)))}"
    cidr_block        = "${lookup(null_resource.webapp_1.triggers, count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"
    map_public_ip_on_launch = false

    tags {
        "Name" = "${var.vpc_name} webapp_1-${element(split(",", lookup(var.azs, var.region)), count.index)}"
    }
}

output "snet_webapp_1" {
    value = ["${aws_subnet.webapp_1.*.id}"]
}

## DB subnets
resource "aws_subnet" "db_1" {
    vpc_id            = "${aws_vpc.main.id}"
    count             = "${length(split(",", lookup(var.azs, var.region)))}"
    cidr_block        = "${lookup(null_resource.db_1.triggers, count.index)}"
    availability_zone = "${element(split(",", lookup(var.azs, var.region)), count.index)}"
    map_public_ip_on_launch = false

    tags {
        "Name" = "${var.vpc_name} db_1-${element(split(",", lookup(var.azs, var.region)), count.index)}"
    }
}

output "snet_db_1" {
    value = ["${aws_subnet.db_1.*.id}"]
}
