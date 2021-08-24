# declaring all avaialability zones in AWS available
data "aws_availability_zones" "available-zones" {
  state = "available"
}

# create vpc
resource "aws_vpc" "my_vpc" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support

  tags = {
    Name = "%your_name%-vpc"
  }
}

# create a random resource to allow shuffling of all avaialbility zones, to give room for more subnets
resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available-zones.names
  result_count = var.max_subnets
}

# create private subnets
resource "aws_subnet" "private-subnets" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = var.private_sn_count
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "Private-Subnet"
  }
}

# create public subnets
resource "aws_subnet" "public-subnets" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = var.public_sn_count
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "Public-Subnet"
  }
}

# create internet gateway
resource "aws_internet_gateway" "my-ig" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "%your_name%-ig"
  }
}

# create Elastic IP
resource "aws_eip" "my-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.my-ig]

  tags = {
    Name = "%your_name%-eip"
  }
}

# create nat gateway
resource "aws_nat_gateway" "my-ng" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = element(aws_subnet.public-subnets.*.id, 0)
  depends_on    = [aws_internet_gateway.my-ig]

  tags = {
    Name = "%your_name%-gateway"
  }
}

# create private route table
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "private-rtb"
  }
}

# create route for the private route table and attatch a nat gateway to it
resource "aws_route" "private-rtb-route" {
  route_table_id         = aws_route_table.private-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.my-ng.id
}

# associate all private subnets to the private rout table
resource "aws_route_table_association" "private-subnets-assoc" {
  subnet_id      = aws_subnet.private-subnets[0].id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route_table_association" "private-subnets-assoc-2" {
  subnet_id      = aws_subnet.private-subnets[1].id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route_table_association" "private-subnets-assoc-3" {
  subnet_id      = aws_subnet.private-subnets[2].id
  route_table_id = aws_route_table.private-rtb.id
}

resource "aws_route_table_association" "private-subnets-assoc-4" {
  subnet_id      = aws_subnet.private-subnets[3].id
  route_table_id = aws_route_table.private-rtb.id
}

# create route table for the public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "public-rtb"
  }
}

# create route for the public route table and attach the internet gateway
resource "aws_route" "public-rtb-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-ig.id
}

# associate all public subnets to the public route table
resource "aws_route_table_association" "public-subnets-assoc" {
  subnet_id      = aws_subnet.public-subnets[0].id
  route_table_id = aws_route_table.public-rtb.id
}

resource "aws_route_table_association" "public-subnets-assoc-1" {
  subnet_id      = aws_subnet.public-subnets[1].id
  route_table_id = aws_route_table.public-rtb.id
}


locals {
  security_groups = []
}
# create all security groups dynamically
resource "aws_security_group" "my-sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.my_vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "%your_name%-sg"
  }
}

resource "aws_security_group_rule" "ALB" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.my-sg["ALB"].id
}

resource "aws_security_group_rule" "bastion" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "-1"
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.my-sg["bastion"].id
}

resource "aws_security_group_rule" "nginx-ALB" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["ALB"].id
  security_group_id        = aws_security_group.my-sg["nginx"].id
}

resource "aws_security_group_rule" "nginx-bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["bastion"].id
  security_group_id        = aws_security_group.my-sg["nginx"].id
}

resource "aws_security_group_rule" "IALB" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["nginx"].id
  security_group_id        = aws_security_group.my-sg["IALB"].id
}

resource "aws_security_group_rule" "webservers" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["IALB"].id
  security_group_id        = aws_security_group.my-sg["webservers"].id
}

resource "aws_security_group_rule" "datalayer-nfs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["webservers"].id
  security_group_id        = aws_security_group.my-sg["data-layer"].id
}

resource "aws_security_group_rule" "datalayer-mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my-sg["webservers"].id
  security_group_id        = aws_security_group.my-sg["data-layer"].id
}