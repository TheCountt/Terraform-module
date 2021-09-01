# create instance for bastion host
resource "aws_instance" "Bastion" {
  ami                         = var.ami-bastion
  instance_type               = var.instance_type
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.keypair

  tags = {
    Name = "terraform_bastion"
  }
}


# create instance for nginx
resource "aws_instance" "nginx" {
  ami                         = var.ami-nginx
  instance_type               = var.instance_type
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.keypair

  tags = {
    Name = "terraform_nginx"
  }
}


# create instance for web server
resource "aws_instance" "webserver" {
  ami                         = var.ami-webserver
  instance_type               = var.instance_type
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.keypair

  tags = {
    Name = "terraform_webserver"
  }
}