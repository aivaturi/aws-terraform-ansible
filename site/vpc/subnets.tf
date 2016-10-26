resource "null_resource" "public" {
    triggers = {
        "0" = "${cidrsubnet(var.vpc_cidr_block, 8, 1)}"
        "1" = "${cidrsubnet(var.vpc_cidr_block, 8, 2)}"
    }
}

resource "null_resource" "mgmt" {
    triggers = {
        "0" = "${cidrsubnet(var.vpc_cidr_block, 8, 3)}"
        "1" = "${cidrsubnet(var.vpc_cidr_block, 8, 4)}"
    }
}

resource "null_resource" "webapp_1" {
    triggers = {
        "0" = "${cidrsubnet(var.vpc_cidr_block, 8, 11)}"
        "1" = "${cidrsubnet(var.vpc_cidr_block, 8, 12)}"
    }
}

resource "null_resource" "db_1" {
    triggers = {
        "0" = "${cidrsubnet(var.vpc_cidr_block, 8, 21)}"
        "1" = "${cidrsubnet(var.vpc_cidr_block, 8, 22)}"
    }
}
