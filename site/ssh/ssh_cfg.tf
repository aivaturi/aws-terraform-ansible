data "template_file" "ssh_config" {
    vars {
        bastion_public_ip = "${var.bastion_public_ip}"
        ssh_key_file = "${var.ssh_key_file}"
        ip_glob = "${var.ip_glob}"
    }
    
    template = "${file("${path.module}/ssh_cfg.tpl")}"
}

resource "null_resource" "bastion_jump_host" {
    provisioner "local-exec" {
        command = "echo \"${data.template_file.ssh_config.rendered}\" > /tmp/terraform_ansible_ssh.cfg"
    }
}

resource "null_resource" "check_ssh" {
    provisioner "local-exec" {
        command = "exec ${path.module}/check_bastion_ssh.sh ${var.bastion_public_ip}"
    }
}

resource "null_resource" "wait" {
    depends_on = ["null_resource.check_ssh"]
    provisioner "local-exec" {
        command = "touch /tmp/terraform-${var.vpc_name}-bastion-alive"
    }
}
