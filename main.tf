locals {
  availability_zones_count = var.all_availability_zones ? length(data.aws_availability_zones.this.zone_ids) : 2

  nat_gateways_count = var.nat_gateway_for_each_subnet ? local.availability_zones_count : 1

  aws_flog_log_destination      = var.flow_log_destination == "cloudwatch" ? try(aws_cloudwatch_log_group.this[0].arn, "") : try(aws_s3_bucket.this[0].arn, "")
  aws_flog_log_iam_role_arn     = try(aws_iam_role.this[0].arn, null)
  aws_flog_log_destination_type = var.flow_log_destination == "s3" ? "s3" : null

  subnet_netnum_factor = {
    public  = 0
    private = local.availability_zones_count
  }
}

resource "random_id" "this" {
  byte_length = 1

  keepers = {
    cidr_block = var.cidr_block
  }
}

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_flow_log" "this" {
  count = var.create_vpc && var.flow_log_enable ? 1 : 0

  iam_role_arn         = local.aws_flog_log_iam_role_arn
  log_destination      = local.aws_flog_log_destination
  log_destination_type = local.aws_flog_log_destination_type
  traffic_type         = "ALL"
  vpc_id               = var.create_vpc ? aws_vpc.this[0].id : data.aws_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create_vpc && var.flow_log_enable && var.flow_log_destination == "cloudwatch" ? 1 : 0

  name              = "${var.name}-flow-log-${random_id.this.hex}"
  retention_in_days = 14

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "this" {
  count = var.create_vpc && var.flow_log_enable && var.flow_log_destination == "s3" ? 1 : 0

  bucket = "${var.name}-flow-log-${random_id.this.hex}"

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "this" {
  count = var.create_vpc && var.flow_log_enable && var.flow_log_destination == "cloudwatch" ? 1 : 0

  name = "${var.name}-flow-log-${random_id.this.hex}"

  assume_role_policy    = data.aws_iam_policy_document.role.json
  force_detach_policies = true
  path                  = "/"

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "this" {
  count = var.create_vpc && var.flow_log_enable && var.flow_log_destination == "cloudwatch" ? 1 : 0

  name = "${var.name}-flow-log-${random_id.this.hex}"

  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.role_policy_cloudwatch.json

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_internet_gateway" "this" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "nat" {
  count = var.create_vpc ? local.nat_gateways_count : 0

  vpc = true

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
    Network   = "NAT"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.create_vpc && var.create_nat_gateway ? local.nat_gateways_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = local.nat_gateways_count == 1 ? aws_subnet.public[0].id : aws_subnet.public[count.index].id

  tags = {
    Name      = var.name
    Module    = path.module
    Workspace = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "public" {
  count = var.create_vpc ? local.availability_zones_count : 0

  availability_zone       = data.aws_availability_zones.this.names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index + local.subnet_netnum_factor.public)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.this[0].id

  tags = {
    Name = var.name

    Module     = path.module
    Workspace  = terraform.workspace
    SubnetType = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "public" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = var.name

    Module     = path.module
    Workspace  = terraform.workspace
    SubnetType = "public"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "public" {
  count = var.create_vpc ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc ? local.availability_zones_count : 0

  route_table_id = aws_route_table.public[0].id
  subnet_id      = aws_subnet.public[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_subnet" "private" {
  count = var.create_vpc ? local.availability_zones_count : 0

  availability_zone       = data.aws_availability_zones.this.names[count.index]
  cidr_block              = cidrsubnet(var.cidr_block, 4, count.index + local.subnet_netnum_factor.private)
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.this[0].id

  tags = {
    Name = var.name

    Module     = path.module
    Workspace  = terraform.workspace
    Network    = "NAT"
    SubnetType = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table" "private" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = var.name

    Module     = path.module
    Workspace  = terraform.workspace
    SubnetType = "private"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "private" {
  count = var.create_vpc && var.create_nat_gateway ? local.nat_gateways_count : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_gateways_count == 1 ? aws_nat_gateway.nat[0].id : aws_nat_gateway.nat[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  count = var.create_vpc ? local.availability_zones_count : 0

  route_table_id = aws_route_table.private[0].id
  subnet_id      = aws_subnet.private[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}
