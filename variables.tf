terraform {
  experiments = [variable_validation]
}

variable "name" {
  type        = string
  description = "Name that will be used in resources names and tags."
  default     = "terraform-aws-vpc-public-private"
}

variable "create_vpc" {
  type        = bool
  description = "Create personal VPC."
  default     = true
}

variable "all_availability_zones" {
  type        = bool
  description = "Use all Availability Zones in the VPC. Will use 2 AZ if \"false\"."
  default     = true
}

variable "create_nat_gateway" {
  type        = bool
  description = "Create NAT Gateway."
  default     = true
}

variable "nat_gateway_for_each_subnet" {
  type        = bool
  description = "Create NAT Gateway for each subnet. Will create 1 NAT Gateway if \"false\"."
  default     = false
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/(1[6-9]|2[0-8]))$", var.cidr_block))
    error_message = "CIDR block parameter must be in the form x.x.x.x/16-28."
  }
}

variable "flow_log_enable" {
  type        = bool
  description = "Enable Flow log for VPC."
  default     = true
}

variable "flow_log_destination" {
  type        = string
  description = "Provides a VPC/Subnet/ENI Flow Log to capture IP traffic for a specific network interface, subnet, or VPC."
  default     = "cloudwatch"

  validation {
    condition     = contains(["cloudwatch", "s3"], var.flow_log_destination)
    error_message = "Logs can be sent only to a CloudWatch Log Group or a S3 Bucket."
  }
}
