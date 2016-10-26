
resource "aws_route53_zone" "root" {
    name = "${var.dns_domain}"
    vpc_id = "${aws_vpc.main.id}"
}

output "dns_zone_id" {
    value = "${aws_route53_zone.root.zone_id}"
}