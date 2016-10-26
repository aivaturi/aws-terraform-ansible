## Default internet gateway
resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.main.id}"
}

/* ----- Public route start ----- */
## Public route table
resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }
    tags {
        Name = "public_subnet_route_table"
    }
}

## Public route table association
resource "aws_route_table_association" "public" {
    count          = "${length(split(",", lookup(var.azs, var.region)))}"
    subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}
/* ----- Public route end ----- */


/* ----- Mgmt subnet route start ----- */
## Mgmt NAT GW EIP
resource "aws_eip" "mgmt_nat_eip" {
    count  = "${length(split(",", lookup(var.azs, var.region)))}"
    vpc    = true
}

## NAT Gateway for mgmt subnets
resource "aws_nat_gateway" "mgmt_nat_gw" {
    count          = "${length(split(",", lookup(var.azs, var.region)))}"
    allocation_id  = "${element(aws_eip.mgmt_nat_eip.*.id, count.index)}"
    subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
    depends_on     = ["aws_internet_gateway.default"]
}

## Mgmt subnet route table
resource "aws_route_table" "mgmt_rt" {
    vpc_id = "${aws_vpc.main.id}"
    count  = "${length(split(",", lookup(var.azs, var.region)))}"
    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = "${element(aws_nat_gateway.mgmt_nat_gw.*.id, count.index)}"
    }
    tags {
        Name = "mgmt_route_table_${count.index}"
    }
}

## Mgmt route table association
resource "aws_route_table_association" "mgmt_nat" {
    count          = "${length(split(",", lookup(var.azs, var.region)))}"
    subnet_id      = "${element(aws_subnet.mgmt.*.id, count.index)}"
    route_table_id = "${element(aws_route_table.mgmt_rt.*.id, count.index)}"
}
/* ----- Mgmt subnet route end ----- */
