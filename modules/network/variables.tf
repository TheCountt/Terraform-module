# AWS region to deploy the infrastructure
variable "region" {}

# the preffered subnet cidr for the resources
variable "vpc_cidr" {}

# the maxinum number of subnets to be created
variable "max_subnets" {
  type = number
}

# setting enabling functions for the vpc
variable "enable_dns_support" {}

variable "enable_dns_hostnames" {
  default = "true"
}

variable "enable_classiclink" {}

variable "enable_classiclink_dns_support" {}

# private subnets
variable "private_subnets" {
  type = list(any)
}

# public subnets
variable "public_subnets" {
  type = list(any)
}

# the mumber of desired private subnets
variable "private_subnet_count" {
  description = "number of desired private subnets"
  type        = number
}

# the mumber of desired public subnets
variable "public_subnet_count" {
  description = "number of desired public subnets"
  type        = number

}

variable "destination_cidr_block" {
  default = "0.0.0.0/0"
  type = string
}

variable "environment" {
  default = true
}

# the security groups
variable "security_groups" {
  default = {}
}