// # define the hihghest number of subnets
// variable "max_subnets" {}


variable "ami-web" {}


variable "instance_type" {}


variable "instance_profile" {}


variable "keypair" {}

variable "ami-bastion" {}


variable "webservers-sg" {}


variable "bastion-sg" {}


variable "nginx-sg" {}


variable "private_subnets-1" {}


variable "private_subnets-2" {}

 
variable "public_subnets-1" {}

 
variable "public_subnets-2" {}


variable "ami-nginx" {}


variable "nginx-target-group" {}


variable "wordpress-target-group" {}


variable "tooling-target-group" {}

variable "template_az" {}
