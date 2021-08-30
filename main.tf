
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
  ami-bastion     = var.ami
  ami-nginx       = var.ami
  ami-webserver   = var.ami
  subnets-compute = module.network.public_subnets-1
  sg-compute      = module.network.ALB-sg
  keypair         = "terraform-key"
}

#Module for Application Load balancer, this will create Extenal Load balancer and Internal load balancer
module "ALB" {
  source        = "./modules/ALB"
  vpc_id        = module.network.vpc_id
  public-sg     = module.network.ALB-sg
  private-sg    = module.network.IALB-sg
  public-sbn-1  = module.network.public_subnets-1
  public-sbn-2  = module.network.public_subnets-2
  private-sbn-1 = module.network.private_subnets-1
  private-sbn-2 = module.network.private_subnets-2
}
