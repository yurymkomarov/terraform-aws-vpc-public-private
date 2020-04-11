output "vpc" {
  value = try(aws_vpc.this[0], data.aws_vpc.default)
}

output "nat_gateway" {
  value = try(aws_nat_gateway.nat, null)
}

output "subnets" {
  value = {
    public  = try(aws_subnet.public, data.aws_subnet.default)
    private = try(aws_subnet.private, data.aws_subnet.default)
  }
}
