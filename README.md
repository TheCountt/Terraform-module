# TERRAFORM MODULES

Modules serve as containers that allow to logically group Terraform codes for similar resources in the same domain (e.g., Compute, Networking, AMI, etc.). One root module can call other child modules and insert their configurations when applying Terraform config. This concept makes your code structure neater, and it allows different team members to work on different parts of configuration at the same time.

You can also create and publish your modules to Terraform Registry for others to use and use someone’s modules in your projects.

Module is just a collection of .tf and/or .tf.json files in a directory.

You can refer to existing child modules from your root module by specifying them as a source, like this:

```
module "network" {
  source = "./modules/network"
}
```

Note that the path to ‘network’ module is set as relative to your working directory.

Or you can also directly access resource outputs from the modules, like this:

```
resource "aws_elb" "example" {
  # ...

  instances = module.servers.instance_ids
}
```
In the example above, you will have to have module ‘servers’ to have output file to expose variables for this resource.


## REFACTOR YOUR PROJECT USING MODULES

- Refactor your project using Modules

Break down your Terraform codes to have all resources in their respective modules. Combine resources of a similar type into directories within a ‘modules’ directory, for example, like this:

```
- modules
  - ALB
  - EFS
  - RDS
  - autoscaling
  - compute
  - network
  - security
  ```
  Each module should contain  the following files:

- main.tf (or %resource_name%.tf) file(s) with resources blocks

- outputs.tf (optional, if you need to refer outputs from any of these resources in your root module)

- variables.tf (as we learned before - it is a good practice not to hard code the values and use variables)

It is also recommended to configure providers and backends sections in separate files in the root module.

Refactor each module to use variables, for all the attributes that need to be configured.

###  Network module
In the `main.tf` file, paste the code below:
```
# declaring all avaialability zones in AWS available
data "aws_availability_zones" "available-zones" {
  state = "available"
}

# create vpc
resource "aws_vpc" "terraform" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support

  tags = {
    Name = "terraform-vpc"
  }
}


# create a random resource to allow shuffling of all avaialbility zones, to give room for more subnets
resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available-zones.names
  result_count = var.max_subnets
}

# create private subnets
resource "aws_subnet" "private-subnets" {
  vpc_id                  = aws_vpc.terraform.id
  count                   = var.private_subnet_count
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "Private-Subnet"
  }

}

# create public subnets
resource "aws_subnet" "public-subnets" {
  vpc_id                  = aws_vpc.terraform.id
  count                   = var.public_subnet_count
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "Public-Subnet"
  }

}

# create internet gateway
resource "aws_internet_gateway" "terraform-ig" {
  vpc_id = aws_vpc.terraform.id
  tags = {
    Name = "terraform-ig"
  }
}


# create Elastic IP
resource "aws_eip" "terraform-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.terraform-ig]

  tags = {
    Name = "terraform-eip"
  }
}

# create nat gateway
resource "aws_nat_gateway" "terraform-ng" {
  allocation_id = aws_eip.terraform-eip.id
  subnet_id     = element(aws_subnet.public-subnets.*.id, 0)
  depends_on    = [aws_internet_gateway.terraform-ig]

  tags = {
    Name = "nat-gateway"
  }
}


# create private route table
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.terraform.id
  tags = {
    Name = "private-rtb"
  }
}

# create route for the private route table and attatch a nat gateway to it
resource "aws_route" "private-rtb-route" {
  route_table_id         = aws_route_table.private-rtb.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_nat_gateway.terraform-ng.id
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
  vpc_id = aws_vpc.terraform.id
  tags = {
    Name = "public-rtb"
  }
}



# create route for the public route table and attach the internet gateway
resource "aws_route" "public-rtb-route" {
  route_table_id         = aws_route_table.public-rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terraform-ig.id
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
  # http_port = 
  # any_port = 
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

# create all security groups dynamically
resource "aws_security_group" "terraform-sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.terraform.id

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
    protocol    = local.any_protocol
    cidr_blocks = local.all_ips
  }

  tags = {
    Name = "terraform-sg"
  }
}

resource "aws_security_group_rule" "bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = local.any_protocol
  cidr_blocks              = local.all_ips
  security_group_id        = aws_security_group.terraform-sg["bastion"].id
}

resource "aws_security_group_rule" "nginx-ALB" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["ALB"].id
  security_group_id        = aws_security_group.terraform-sg["nginx"].id
}


resource "aws_security_group_rule" "nginx-bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["bastion"].id
  security_group_id        = aws_security_group.terraform-sg["nginx"].id
}

resource "aws_security_group_rule" "IALB" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["nginx"].id
  security_group_id        = aws_security_group.terraform-sg["IALB"].id
}

resource "aws_security_group_rule" "webservers" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["IALB"].id
  security_group_id        = aws_security_group.terraform-sg["webservers"].id
}

resource "aws_security_group_rule" "datalayer-nfs" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["webservers"].id
  security_group_id        = aws_security_group.terraform-sg["data-layer"].id
}

resource "aws_security_group_rule" "datalayer-mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = local.tcp_protocol
  source_security_group_id = aws_security_group.terraform-sg["webservers"].id
  security_group_id        = aws_security_group.terraform-sg["data-layer"].id
}
```









