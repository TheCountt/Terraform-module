output "address" {
  value = aws_db_instance.terraform-rds.address
  description = "Connect to database at this endpoint"
}

output "port" {
  value = aws_db_instance.terraform-rds.port
  description = "The port the database is listening on"
}