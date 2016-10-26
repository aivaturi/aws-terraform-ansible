
## Approved remote IP white list
resource "aws_security_group" "remote_ip_white_list" {
    name        = "remote_ip_white_list"
    description = "Connection from approved IPs"
    vpc_id      = "${aws_vpc.main.id}"

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = "${var.remote_ips}"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "Remote IP White List"
    }
}

output "sg_remote_ip_white_list" {
    value = "${aws_security_group.remote_ip_white_list.id}"
}

## Allow mgmt hosts (Bastion, Ansible, Nagios & Jenkins)
resource "aws_security_group" "allow_mgmt_hosts" {
    name        = "allow_mgmt_hosts"
    description = "Allow all management hosts"
    vpc_id      = "${aws_vpc.main.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
        Name = "Allow all mgmt hosts"
    }
}

output "sg_allow_mgmt_hosts" {
    value = "${aws_security_group.allow_mgmt_hosts.id}"
}

resource "aws_security_group" "allow_access_to_consul" {
    name        = "allow_access_to_consul"
    description = "Allow access to all Consul ports"
    vpc_id      = "${aws_vpc.main.id}"

    ingress {
        from_port   = 8300
        to_port     = 8302
        protocol    = "tcp"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }
    ingress {
        from_port   = 8400
        to_port     = 8400
        protocol    = "tcp"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }
    ingress {
        from_port   = 8500
        to_port     = 8500
        protocol    = "tcp"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }
    ingress {
        from_port   = 8301
        to_port     = 8302
        protocol    = "udp"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }
    ingress {
        from_port   = 8600
        to_port     = 8600
        protocol    = "udp"
        cidr_blocks = ["${var.vpc_cidr_block}"]
    }


    tags {
        Name = "Allow access to Consul ports"
    }
}

output "sg_allow_access_to_consul" {
    value = "${aws_security_group.allow_access_to_consul.id}"
}
