resource "random_shuffle" "private-sb" {
  input        = var.private_subnets
  result_count = 2
}


# Create DB Subnet Group
resource "aws_db_subnet_group" "terraform-rds_subnet-group" {
  name       = "terraform-rds_subnet-group"
  subnet_ids = random_shuffle.private-sb.result

  tags = {
    Name = "terraform-rds_subnet-group"
  }
}

# Create AWS Secret Manager
data "aws_secretsmanager_secret_version" "credentials" {
  # Fill in the name you gave to your secret
  secret_id = "db-secret"
}

locals {
  db_secret = jsondecode(
    data.aws_secretsmanager_secret_version.credentials.secret_string
  )
}

# Create DB instance
resource "aws_db_instance" "terraform-rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = local.db_secret.username
  password             = local.db_secret.password
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = "aws_db_subnet_group.terraform-rds_subnet-group.name"
  vpc_security_group_ids = [var.db-sg]
  skip_final_snapshot  = true
  multi_az             = true

}
