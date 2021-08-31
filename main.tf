
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
  public_subnet_count            = 2
  private_subnet_count           = 4
  private_subnets                = [for i in range(1, 8, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets                 = [for i in range(2, 5, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  security_groups                = local.security_groups
}

# The Module creates instances for various servers
module "compute" {
  source          = "./modules/compute"
  instance_type   = var.instance_type
  ami-bastion     = var.ami
  ami-nginx       = var.ami
  ami-webserver   = var.ami
  subnets-compute = module.network.public_subnets-1
  sg-compute      = module.network.ALB-sg
  keypair         = "terraform-key"
}

#Module for Application Load balancer, this will create Extenal Load balancer and Internal load balancer
module "ALB" {
  source            = "./modules/ALB"
  vpc_id            = module.network.vpc_id
  public-sg         = module.network.ALB-sg
  private-sg        = module.network.IALB-sg
  public-subnets-1  = module.network.public_subnets-1
  public-subnets-2  = module.network.public_subnets-2
  private-subnets-1 = module.network.private_subnets-1
  private-subnets-2 = module.network.private_subnets-2
}

# Module for Elastic Filesystem; this module will creat elastic file system isn the webservers availablity
# zone and allow traffic fro the webservers

module "EFS" {
  source       = "./modules/EFS"
  efs-subnet-1 = module.network.private_subnets-1
  efs-subnet-2 = module.network.private_subnets-2
  efs-sg       = module.network.data-layer
  account_no   = var.account_no
}

# Module for Autoscaling groups; this module will create all autoscaling groups for bastion,
# nginx, and the webservers.

module "autoscaling" {
  source                 = "./modules/autoscaling"
  instance_type          = var.instance_type
  ami-web                = var.ami
  ami-bastion            = var.ami
  ami-nginx              = var.ami
  template_az            = var.region
  webservers-sg          = module.network.webservers-sg
  bastion-sg             = module.network.bastion-sg
  nginx-sg               = module.network.nginx-sg
  wordpress-target-group = module.ALB.wordpress-target-group
  nginx-target-group     = module.ALB.nginx-target-group
  tooling-target-group   = module.ALB.tooling-target-group
  instance_profile       = module.network.instance_profile
  public_subnets-1       = module.network.public_subnets-1
  public_subnets-2       = module.network.public_subnets-2
  private_subnets-1      = module.network.private_subnets-1
  private_subnets-2      = module.network.private_subnets-2
  keypair                = "terraform-key"

}

# RDS module; this module will create the RDS instance in the private subnet

module "RDS" {
  source          = "./modules/RDS"
  db-sg           = module.network.data-layer
  private_subnets = module.network.private_subnets
}