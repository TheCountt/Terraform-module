# output for the first public subnet in the index
output "public_subnets-1" {
  value       = aws_subnet.public-subnets[0].id
  description = "The first public subnet in the subnets"
}

# output for the second public subnet in the index
output "public_subnets-2" {
  value       = aws_subnet.public-subnets[1].id
  description = "The first public subnet"
}

# output for the first private subnet in the index
output "private_subnets-1" {
  value       = aws_subnet.private-subnets[0].id
  description = "The first private subnet"
}

# output for the second private subnet in the index
output "private_subnets-2" {
  value       = aws_subnet.private-subnets[1].id
  description = "The second private subnet"
}


# output for the third private subnet in the index
output "private_subnets-3" {
  value       = aws_subnet.private-subnets[2].id
  description = "The third private subnet"
}

output "private_subnets" {
  value       = aws_subnet.private-subnets[*].id
  description = "All private subnet"
}


# output for the fourth private subnet in the index
output "private_subnets-4" {
  value       = aws_subnet.private-subnets[3].id
  description = "The fourth private subnet"
}



# output for application load balancer security group
output "ALB-sg" {
  value = aws_security_group.terraform-sg["ALB"].id
}


# output for the intetrnal load balancer security group
output "IALB-sg" {
  value = aws_security_group.terraform-sg["IALB"].id
}


# output for the bastion security group
output "bastion-sg" {
  value = aws_security_group.terraform-sg["bastion"].id
}


# output for the nginx security group
output "nginx-sg" {
  value = aws_security_group.terraform-sg["nginx"].id
}


# output for the webservers security group
output "webservers-sg" {
  value = aws_security_group.terraform-sg["webservers"].id
}


# output for the data layer security group
output "data-layer" {
  value = aws_security_group.terraform-sg["data-layer"].id
}


# output for the vpc id
output "vpc_id" {
  value = aws_vpc.terraform.id
}

# output for the max subnets
output "max_subnets" {
  value = 10
}


# output for the instance profile
output "instance_profile" {
  value = aws_iam_instance_profile.terraform-profile.id
}
