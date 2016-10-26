Network Layout
==============

Assuming you're using 10.10.0.0/16...

# All external facing instances, including
# NAT gateways reside in public subnet.
# Bastion host has to reside here as well.
public     : 10.10.1.0/24, 10.10.2.0/24

# All the following subnets will route data
# through a NAT gateway.

Management(mgmt) : 10.10.3.0/24, 10.10.4.0/24

App (Web) Server : 10.10.11.0/24, 10.10.12.0/24

# Database subnet has:
#    MongoDB, Redis, ElasticSearch etc
Database   : 10.10.21.0/24, 10.10.22.0/24
