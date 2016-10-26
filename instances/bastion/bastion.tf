
data "template_file" "userdata" {
    template = "${file("${path.module}/userdata.tpl")}"

    vars {
        dns_domain = "${var.dns_domain}"
        hostname = "${element(split(".", var.dns_domain), 0)}bastion"
    }
}

provider "aws" {
    region = "${var.region}"
}

data "aws_ami" "ubuntu" {
    most_recent = true
    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
    }
    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion" {
    ami                         = "${data.aws_ami.ubuntu.id}"
    instance_type               = "t2.micro"
    key_name                    = "${var.vpc_name}_ssh_key"
    subnet_id                   = "${var.subnet}"
    vpc_security_group_ids      = ["${var.sg}"]
    associate_public_ip_address = true

    root_block_device {
        volume_size = 40
    }

    tags {
        Name = "${var.vpc_name} Bastion"
        role = "mgmt"
    }

    connection {
        type = "ssh"
        user = "ubuntu"
        private_key = "${file(var.ssh_key_file)}"
    }

    provisioner "file" {
        content = "${data.template_file.userdata.rendered}"
        destination = "/home/ubuntu/host_setup.sh"
    }

    provisioner "file" {
        source = "${var.ssh_key_file}"
        destination = "/home/ubuntu/.ssh/id_rsa"
    }

    provisioner "remote-exec" {
        inline = [
            "cd /home/ubuntu",
            "chmod 400 /home/ubuntu/.ssh/id_rsa",
            "chmod +x ./host_setup.sh",
            "echo StrictHostKeyChecking no >> /home/ubuntu/.ssh/config",
            "sudo ./host_setup.sh"
        ]
    }
}

resource "aws_route53_record" "bastion" {
    zone_id = "${var.dns_zone_id}"
    name    = "${element(split(".", var.dns_domain), 0)}bastion"
    type    = "A"
    ttl     = "300"
    records = ["${aws_instance.bastion.private_ip}"]
}

resource "aws_route53_record" "bastion_cname" {
    zone_id = "${var.dns_zone_id}"
    name    = "bastion"
    type    = "CNAME"
    ttl     = "60"
    records = ["${element(split(".", var.dns_domain), 0)}bastion.${var.dns_domain}"]
}

output "bastion_ip" {
    value = "${aws_instance.bastion.private_ip}"
}

output "bastion_public_ip" {
    value = "${aws_instance.bastion.public_ip}"
}

resource "aws_security_group_rule" "allow_bastion_to_ssh_22" {
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = ["${aws_instance.bastion.private_ip}/32"]
    security_group_id = "${var.sg_mgmt}"
}

resource "aws_security_group_rule" "allow_icmp" {
    type              = "ingress"
    from_port         = 8
    to_port           = 0
    protocol          = "icmp"
    cidr_blocks       = ["${var.vpc_cidr_block}"]
    security_group_id = "${var.sg_mgmt}"
}

resource "null_resource" "tpl_ip_octet" {
    triggers {
        "0" = "${element(split(".", cidrhost(var.vpc_cidr_block, 1)), 0)}"
        "1" = "${element(split(".", cidrhost(var.vpc_cidr_block, 1)), 1)}"
    }
}

output "network_ip_glob" {
    value = "${lookup(null_resource.tpl_ip_octet.triggers, 0)}.${lookup(null_resource.tpl_ip_octet.triggers, 1)}.*.*"
}
