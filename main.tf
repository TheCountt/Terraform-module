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
  source                         = "./modules/network"
  region                         = var.region
  vpc_cidr                       = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support
  max_subnets                    = 10
  public_subnet_count                = 2
  private_subnet_count               = 4
  private_subnets                = [for i in range(1, 8, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets                 = [for i in range(2, 5, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  security_groups                = local.security_groups
}

# The Module creates instances for various servers
module "compute" {
  source          = "./modules/compute"
  ami-bastion     = "ami-054965c6cd7c6e462"
  ami-nginx       = "ami-054965c6cd7c6e462"
  ami-webserver   = "ami-054965c6cd7c6e462"
  subnets-compute = module.network.public_subnets-1
  sg-compute      = module.network.ALB-sg
  keypair         = "devops-key"
}

#Module for Application Load balancer, this will create Extenal Load balancer and internal load balancer
module "ALB" {
  source        = "./modules/ALB"
  public-sg     = module.network.ALB-sg
  private-sg    = module.network.IALB-sg
  public-sbn-1  = module.network.public_subnets-1
  public-sbn-2  = module.network.public_subnets-2
  private-sbn-1 = module.network.private_subnets-1
  private-sbn-2 = module.network.private_subnets-2
}

# Module for Autoscaling groups; this module will create all autoscaling groups for bastion,
# nginx, and the webservers.

# module "autoscaling" {
#   source            = "./modules/autoscaling"
#   ami-web           = "ami-054965c6cd7c6e462"
#   ami-bastion       = "ami-054965c6cd7c6e462"
#   ami-nginx         = "ami-054965c6cd7c6e462"
#   template_az       = var.region
#   web-sg            = module.network.web-sg
#   bastion-sg        = module.network.bastion-sg
#   nginx-sg          = module.network.nginx-sg
#   wordpress-alb-tgt = module.ALB.wordpress-tgt
#   nginx-alb-tgt     = module.ALB.nginx-tgt
#   tooling-alb-tgt   = module.ALB.tooling-tgt
#   instance_profile  = module.network.instance_profile
#   public_subnets-1  = module.network.public_subnets-1
#   public_subnets-2  = module.network.public_subnets-2
#   private_subnets-1 = module.network.private_subnets-1
#   private_subnets-2 = module.network.private_subnets-2
#   keypair           = "devops-key"

# }

# module "EFS" {
#   source       = "./modules/EFS"
#   efs-subnet-1 = module.network.private_subnets-1
#   efs-subnet-2 = module.network.private_subnets-2
#   efs-sg       = module.network.data-layer
#   account_no   = var.account_no
# }

# # RDS module; this module will create the RDS instance in the private subnet

# module "RDS" {
#   source          = "./modules/RDS"
#   db-password     = var.db-password
#   db-username     = var.db-username
#   db-sg           = module.network.data-layer
#   private_subnets = module.network.private_subnets
# }

