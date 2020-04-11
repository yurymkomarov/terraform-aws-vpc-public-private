# AWS VPC with Public and Private Subnets (NAT)

The configuration for this module includes a virtual private cloud (VPC) with a public subnets and a private subnets.

We recommend this module if you want to run a public-facing web application, while maintaining back-end servers that aren't publicly accessible. A common example is a multi-tier website, with the web servers in a public subnets and the database servers in a private subnets.

## Overview

The following diagram shows the key components of the configuration for this module:

![The following diagram shows the key components of the configuration for this module](images/diagram.png)

The configuration for this module includes the following:

- A VPC with with size /16 - /28 IPv4 CIDR block (example: 10.0.0.0/16)
- A public subnet with a size /20 IPv4 CIDR block (example: 10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20)
- A private subnet with a size /20 IPv4 CIDR block (example: 10.0.48.0/20, 10.0.64.0/20, 10.0.80.0/20)
- An Internet gateway. This connects the VPC to the Internet and to other AWS services.
- A NAT gateway with its own Elastic IPv4 address.
- A custom route table associated with the public subnet. This route table contains an entry that enables instances in the subnet to communicate with other instances in the VPC over IPv4, and an entry that enables instances in the subnet to communicate directly with the Internet over IPv4.
- The main route table associated with the private subnet. The route table contains an entry that enables instances in the subnet to communicate with other instances in the VPC over IPv4, and an entry that enables instances in the subnet to communicate with the Internet through the NAT gateway over IPv4.
