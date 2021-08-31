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

Do not forget the Reference Architecture

![tooling_project_15](https://user-images.githubusercontent.com/76074379/131581164-07962e3f-9e20-4538-8be8-4649e8fbfdcf.png)


Break down your Terraform codes to have all resources in their respective modules. Combine resources of a similar type into directories within a ‘modules’ directory, for example, like this:

```
- modules
  - ALB
  - EFS
  - RDS
  - autoscaling
  - compute
  - network
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

Paste the below code in the `variable.tf` file

```
# AWS region to deploy the infrastructure
variable "region" {}

# the preffered subnet cidr for the resources
variable "vpc_cidr" {}

# the maxinum number of subnets to be created
variable "max_subnets" {
  type = number
}

# setting enabling functions for the vpc
variable "enable_dns_support" {}

variable "enable_dns_hostnames" {
  default = "true"
}

variable "enable_classiclink" {}

variable "enable_classiclink_dns_support" {}

# private subnets
variable "private_subnets" {
  type = list(any)
}

# public subnets
variable "public_subnets" {
  type = list(any)
}

# the mumber of desired private subnets
variable "private_subnet_count" {
  description = "number of desired private subnets"
  type        = number
}

# the mumber of desired public subnets
variable "public_subnet_count" {
  description = "number of desired public subnets"
  type        = number

}

variable "destination_cidr_block" {
  default = "0.0.0.0/0"
  type = string
}

variable "environment" {
  default = true
}

# the security groups
variable "security_groups" {
  default = {}
}
```

We need a terraform file for roles. So we create a `roles.tf` file.(If you are confused about how to go about the infrastructure code, you can always go to the console and document the steps down so as to guide you when writing the terraform code)

```
# create IAM role for all instance
resource "aws_iam_role" "terraform-role" {
  name = "terraform-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "terraform-role"
  }
}

# create IAM policy for all instance
resource "aws_iam_policy" "terraform-policy" {
  name        = "terraform_policy"
  path        = "/"
  description = "terraform policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# attach IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "terraform-attach" {
  role       = aws_iam_role.terraform-role.name
  policy_arn = aws_iam_policy.terraform-policy.arn
}

# create instance profile and attach to the IAM role
resource "aws_iam_instance_profile" "terraform-profile" {
  name = "aws_instance_profile_terraform-profile"
  role = aws_iam_role.terraform-role.name
}
```

In the `outputs.tf` file, paste the below code soas to print the outputs we specified on screen for us

```
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
```
Run command `terraform init` and `terraform plan`.( If there are problems with your code, there will be an error message here first)

### Compute Module

In the `main.tf` file, paste the code below:

```
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
```

In the `variables.tf` file, paste the code below:
```
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
```
We need to upload our PEM key so we can spin some resources such as instances. So we create a new file called `keypair.tf`

- Paste the code below into `keypair.tf`

```
resource "aws_key_pair" "terraform-key" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/id_rsa.pub")
}
```
Run command `terraform init` and `terraform plan`.( If there are problems with your code, there will be an error message here first)

### Module ALB
In the `main.tf` file, paste the following code:
```
/// Resources for Nginx Reverse Proxy

# Create an External(Internet-Facing) Load Balancer
resource "aws_lb" "terraform-external-alb" {
  name     = "terraform-external-alb"
  internal = false
  security_groups = [var.public-sg]
  subnets = [var.public-subnets-1, var.public-subnets-2]

  tags = {
    Name = "terraform-external-alb"
  }
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Create a Target Group
resource "aws_lb_target_group" "nginx-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "nginx-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

# Create Listener for Target Group
resource "aws_lb_listener" "nginx-listener-80" {
  load_balancer_arn = aws_lb.terraform-external-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-target-group.arn
  }
}

/// Resources for Web Servers

# Create Internal Application Load Balancer
resource "aws_lb" "terraform-internal-alb" {
  name     = "terraform-internal-alb"
  internal = true
  security_groups = [var.private-sg]
  subnets = [var.private-subnets-1, var.private-subnets-2]

  tags = {
    Name = "terraform-internal-alb"
  }
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Create Target Group for Webservers

## for tooling website

resource "aws_lb_target_group" "tooling-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "tooling-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

## for wordpress website

resource "aws_lb_target_group" "wordpress-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "wordpress-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

# Create Listeners for the Target Groups
## You can only create a single listener for a port to avoid errors. We will add a listener rule to route traffic
## to the wordpress target group

resource "aws_lb_listener" "webserver-listener-80" {
  load_balancer_arn = aws_lb.terraform-internal-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress-target-group.arn
  }
}

## listener rule for to route requests to tooling target
## A rule was created to route traffic to tooling when the host header changes

resource "aws_lb_listener_rule" "webserver-listener-80-rule" {
  listener_arn = aws_lb_listener.webserver-listener-80.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling-target-group.arn
  }

  condition {
    host_header {
      values = ["tooling.kragrahl.cf"]
    }
  }
}
```
In the `variables.tf` file, paste the following code:

```
variable "public-sg" {
  default = {}
}

variable "private-sg" {
  default = {}
}

variable "public-subnets-1" {
  default = {}
}

variable "public-subnets-2" {
  default = {}
}

variable "private-subnets-1" {
  default = {}
}

variable "private-subnets-2" {
  default = {}
}

variable "vpc_id" {
  default = ""
  type = string
}

```

In the `outputs.tf` file, paste the code below:
```
#output the External Load balancer DNS
output "alb_dns_name" {
  description = "External Load balancer DNS"
  value       = aws_lb.terraform-external-alb.dns_name
}

# output the External Load balancer target group
output "nginx-target-group" {
  description = "External Load balancer target group"
  value       = aws_lb_target_group.nginx-target-group.arn
}


# Output Internal Load balancer target group
output "wordpress-target-group" {
  description = "Internal Load balancer target group"
  value       = aws_lb_target_group.wordpress-target-group.arn
}



# Output Internal Load balancer target group
output "tooling-target-group" {
  description = "Internal Load balancer target group"
  value       = aws_lb_target_group.tooling-target-group.arn
}
```
### Module Autoscaling
In the `main.tf` file, paste the following code:
```
//// Launch Templates ///////

resource "aws_launch_template" "bastion" {
  name = "bastion-launch-template"

  image_id = var.ami-bastion

  instance_type = var.instance_type

  vpc_security_group_ids = [var.bastion-sg]

  iam_instance_profile {
    name = var.instance_profile
  }

  placement {
    availability_zone = var.template_az
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform-bastion"
    }
  }

  # user_data = filebase64("bastion.sh")

    lifecycle {
      create_before_destroy = true
  }
}


resource "aws_launch_template" "nginx" {
  name = "nginx-launch-template"

  image_id = var.ami-nginx

  instance_type = var.instance_type

  vpc_security_group_ids = [var.nginx-sg]

  iam_instance_profile {
    name = var.instance_profile
  }

  placement {
    availability_zone = var.template_az
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform-nginx"
    }
  }

  # user_data = filebase64("nginx.sh")

    lifecycle {
      create_before_destroy = true
  }
}

resource "aws_launch_template" "tooling" {
  name = "tooling-launch-template"

  image_id = var.ami-web

  instance_type = var.instance_type

  vpc_security_group_ids = [var.webservers-sg]

  iam_instance_profile {
    name = var.instance_profile
  }

  placement {
    availability_zone = var.template_az
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform-tooling"
    }
  }

  # user_data = filebase64("tooling.sh")

    lifecycle {
      create_before_destroy = true
  }
}

resource "aws_launch_template" "wordpress" {
  name = "wordpress-launch-template"

  image_id = var.ami-web

  instance_type = var.instance_type

  vpc_security_group_ids = [var.webservers-sg]

  iam_instance_profile {
    name = var.instance_profile
  }

  placement {
    availability_zone = var.template_az
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "terraform-wordpress"
    }
  }

  # user_data = filebase64("wordpress.sh")

    lifecycle {
      create_before_destroy = true
  }
}

////// Autoscaling Group //////

# ---- Autoscaling for bastion  hosts
resource "aws_autoscaling_group" "bastion-asg" {
  name                      = "bastion-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [
    var.public_subnets-1,
    var.public_subnets-2
  ]


  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "terraform-bastion"
    propagate_at_launch = true
  }

}


# ------ Autoscslaling group for nginx reverse proxy

resource "aws_autoscaling_group" "nginx-asg" {
  name                      = "nginx-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [
    var.public_subnets-1,
    var.public_subnets-2
  ]

  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-nginx"
    propagate_at_launch = true
  }
}

# ------ Autoscaling group for tooling webserver

resource "aws_autoscaling_group" "tooling-asg" {
  name                      = "tooling-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [
    var.private_subnets-1,
    var.private_subnets-2
  ]

  launch_template {
    id      = aws_launch_template.tooling.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-tooling"
    propagate_at_launch = true
  }
}

# ------ Autoscaling group for wordpress webserver
resource "aws_autoscaling_group" "wordpress-asg" {
  name                      = "wordpress-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  vpc_zone_identifier = [
    var.private_subnets-1,
    var.private_subnets-2
  ]

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "terraform-wordpress"
    propagate_at_launch = true
  }
}

# attaching autoscaling group of nginx to external load balancer
resource "aws_autoscaling_attachment" "asg_attachment_nginx" {
  autoscaling_group_name = aws_autoscaling_group.nginx-asg.id
  alb_target_group_arn   = var.nginx-target-group
}

# attaching autoscaling group of wordpress to internal load balancer
resource "aws_autoscaling_attachment" "asg_attachment_wordpress" {
  autoscaling_group_name = aws_autoscaling_group.wordpress-asg.id
  alb_target_group_arn   = var.wordpress-target-group
}

# attaching autoscaling group of tooling to internal load balancer
resource "aws_autoscaling_attachment" "asg_attachment_tooling" {
  autoscaling_group_name = aws_autoscaling_group.tooling-asg.id
  alb_target_group_arn   = var.tooling-target-group
}

# creating sns topic for all the auto scaling groups
resource "aws_sns_topic" "terraform-sns" {
  name = "Default_CloudWatch_Alarms_Topic"
}


# creating notification for all the auto scaling groups
resource "aws_autoscaling_notification" "terraform_notifications" {
  group_names = [
    aws_autoscaling_group.bastion-asg.name,
    aws_autoscaling_group.nginx-asg.name,
    aws_autoscaling_group.wordpress-asg.name,
    aws_autoscaling_group.tooling-asg.name,
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.terraform-sns.arn
}

```

In the `variables.tf` file, paste the following code:
```
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
```
Run command `terraform init` and `terraform plan`.( If there are problems with your code, there will be an error message here first)

**Note**: Though it is commented out in the terraform code, we need to create user data scripts that will install the packages we want on the servers that will be spun up by autosccaling resource.

### Module EFS
In the `main.tf` file, paste the code below:
```
# create key from key management system
resource "aws_kms_key" "terraform-kms" {
  description = "KMS key"
  policy = jsonencode({
  "Version": "2012-10-17",
  "Id": "kms-key-policy",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::${var.account_no}:root"},
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
})
}

# create key alias
resource "aws_kms_alias" "alias" {
  name          = "alias/kms"
  target_key_id = aws_kms_key.terraform-kms.key_id
}

# create Elastic file system
resource "aws_efs_file_system" "terraform-efs" {
  encrypted  = true
  kms_key_id = aws_kms_key.terraform-kms.arn

  tags = {
    Name = "terraform-efs"
  }
}


# set first mount target for the EFS 
resource "aws_efs_mount_target" "subnet-1" {
  file_system_id  = aws_efs_file_system.terraform-efs.id
  subnet_id       = var.efs-subnet-1
  security_groups = [var.efs-sg]
}


# set second mount target for the EFS 
resource "aws_efs_mount_target" "subnet-2" {
  file_system_id  = aws_efs_file_system.terraform-efs.id
  subnet_id       = var.efs-subnet-2
  security_groups = [var.efs-sg]
}


# create access point for wordpress
resource "aws_efs_access_point" "wordpress" {
  file_system_id = aws_efs_file_system.terraform-efs.id

  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {
    path = "/wordpress"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }

  }

}


# create access point for tooling
resource "aws_efs_access_point" "tooling" {
  file_system_id = aws_efs_file_system.terraform-efs.id
  posix_user {
    gid = 0
    uid = 0
  }

  root_directory {

    path = "/tooling"

    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = 0755
    }

  }
}
```

In the `variables.tf` file, paste the code below:
```
# first subnets to allow mount to the elastic file system
variable "efs-subnet-2" {}

# second subnets to allow mount to the elastic file system
variable "efs-subnet-1" {}

# security groups for the elastic file system
variable "efs-sg" {}

# account ID for the AWS user
variable "account_no" {} 
```
Run command `terraform init` and `terraform plan`.( If there are problems with your code, there will be an error message here first)

### Module RDS
In the `main.tf` file, paste the code below:
```
resource "random_shuffle" "private-sb" {
  input        = var.private_subnets
  result_count = 3
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
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = local.db_secret.username
  password             = local.db_secret.password
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.terraform-rds_subnet-group.name
  vpc_security_group_ids = [var.db-sg]
  skip_final_snapshot  = true
  multi_az             = true

}
```
In the `variables.tf` file, paste the code below:
```
variable "db-sg" {}

variable "private_subnets" {}
```
In the `outputs.tf` file, paste the code below:
```
output "address" {
  value = aws_db_instance.terraform-rds.address
  description = "Connect to database at this endpoint"
}

output "port" {
  value = aws_db_instance.terraform-rds.port
  description = "The port the database is listening on"
}
```
Run command `terraform init` and `terraform plan`.( If there are problems with your code, there will be an error message here first)

