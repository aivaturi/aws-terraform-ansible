
data "template_file" "userdata" {
    template = "${file("${path.module}/userdata.tpl")}"

    vars {
        dns_domain = "${var.dns_domain}"
        hostname = "${element(split(".", var.dns_domain), 0)}pki"
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

resource "null_resource" "check_bastion" {
    provisioner "local-exec" {
        command = "while ! test -f /tmp/terraform-${var.vpc_name}-bastion-alive; do sleep 5; done"
    }
}

resource "aws_instance" "pki" {
    # If we don't do this, terraform will start
    # parallelizing all operations.
    depends_on = ["null_resource.check_bastion"]

    ami                         = "${data.aws_ami.ubuntu.id}"
    instance_type               = "t2.micro"
    user_data                   = "${data.template_file.userdata.rendered}"
    key_name                    = "${var.vpc_name}_ssh_key"
    subnet_id                   = "${var.subnet}"
    vpc_security_group_ids      = ["${var.sg}"]
    associate_public_ip_address = false

    root_block_device {
        volume_size = 24
    }
    tags {
        Name = "${var.vpc_name} PKI"
        role = "pki"
    }
}

output "pki_server" {
    value = "${aws_instance.pki.private_ip}"
}

resource "aws_route53_record" "pki" {
    zone_id = "${var.dns_zone_id}"
    name    = "${element(split(".", var.dns_domain), 0)}pki"
    type    = "A"
    ttl     = "300"
    records = ["${aws_instance.pki.private_ip}"]
}

resource "aws_route53_record" "pki_cname" {
    zone_id = "${var.dns_zone_id}"
    name    = "pki"
    type    = "CNAME"
    ttl     = "60"
    records = ["${element(split(".", var.dns_domain), 0)}pki.${var.dns_domain}"]
}

resource "null_resource" "check_ssh" {
    provisioner "local-exec" {
        command = "exec ${path.root}/scripts/bin/check_ssh.sh ${var.bastion_public_ip} ${aws_instance.pki.private_ip}"
    }
}

resource "null_resource" "install_pki" {
    depends_on = ["null_resource.check_ssh"]

    provisioner "local-exec" {
        command = "echo \"export EC2_REGION=${var.region}
                   export ANSIBLE_PRIVATE_KEY_FILE=$PWD/${var.vpc_name}_ssh
                   export VPC_ENV_NAME=${var.vpc_name} \" > /tmp/vpc_vars"
    }

    provisioner "local-exec" {
        command = "exec ${path.root}/scripts/run_ansible.sh -i pki -e \\
                     'target=tag_role_pki vpc_zone=${element(split(".", var.dns_domain), 0)} \\
                     vpc_root_domain=${var.dns_domain}'"
    }
}
