# # Get list of availability zones
# data "aws_availability_zones" "available" {
# state = "available"
# }

# provider "aws" {
#   region = var.region
# }

# Module for network; This module will create all the neccessary resources for the entire project,
#such as vpc, subnets, gateways and all neccssary things to enable proper connectivity

module "network" {
  source                         = "C:/Users/user/18-Project/modules/network"
  region                         = var.region
  vpc_cidr                       = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support
  max_subnets                    = 10
  public_sn_count                = 2
  private_sn_count               = 4
  private_subnets                = [for i in range(1, 8, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets                 = [for i in range(2, 5, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  security_groups                = local.security_groups
}

# The Module creates instances for various servers
module "compute" {
  source          = "C:/Users/user/18-Project/modules/compute"
  ami-bastion     = "ami-054965c6cd7c6e462"
  ami-nginx       = "ami-054965c6cd7c6e462"
  ami-webserver   = "ami-054965c6cd7c6e462"
  subnets-compute = module.network.public_subnets-1
  sg-compute      = module.network.ALB-sg
  keypair         = "devops-key"
}