resource "aws_key_pair" "ssh_key" {
    key_name = "${var.vpc_name}_ssh_key"
    public_key = "${file(var.ssh_key_file_pub)}"
}
