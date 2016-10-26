resource "aws_vpc_dhcp_options" "default" {
    domain_name = "${var.dns_domain}"
    domain_name_servers = ["AmazonProvidedDNS"]

    tags {
        Name = "${var.vpc_name} DHCP Options"
    }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
    vpc_id = "${aws_vpc.main.id}"
    dhcp_options_id = "${aws_vpc_dhcp_options.default.id}"
}
