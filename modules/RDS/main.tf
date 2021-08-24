# Create DB Subnet Group
resource "aws_db_subnet_group" "db_instances" {
  name       = "db_instances"
  subnet_ids = [aws_subnet.private_B[0].id, aws_subnet.private_B[1].id]

  tags = {
    Name = "My DB subnet group"
  }
}

# Create rds DB
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "admin"
  password             = "admin1234"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.db_instances.name
  skip_final_snapshot  = true
  multi_az             = "true"
}