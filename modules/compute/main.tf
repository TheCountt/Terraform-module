# create instance for bastion host
resource "aws_instance" "Bastion" {
  ami                         = var.ami-bastion
  instance_type               = "t2.micro"
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = true
  key_name                    = var.keypair

  tags = {
    Name = "%your_name%_bastion"
  }
}


# create instance for nginx
resource "aws_instance" "nginx" {
  ami                         = var.ami-nginx
  instance_type               = "t2.micro"
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = true
  key_name                    = var.keypair

  tags = {
    Name = "%your_name%_nginx"
  }
}


# create instance for web server
resource "aws_instance" "webserver" {
  ami                         = var.ami-webserver
  instance_type               = "t2.micro"
  subnet_id                   = var.subnets-compute
  vpc_security_group_ids      = [var.sg-compute]
  associate_public_ip_address = true
  key_name                    = var.keypair

  tags = {
    Name = "%your_name%_webserver"
  }
}