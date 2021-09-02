variable "subnets-compute" {}
variable "ami-bastion" {}
variable "ami-nginx" {}
variable "ami-webserver" {}

variable "sg-compute" {}

variable "instance_type" {}

variable "associate_public_ip_address" {
  default = true
  type = bool
}

variable "keypair" {
    type = string
    default = "terraform-key"
}