# Create (Internet-facing)Application Load Balancer
resource "aws_lb" "my-aws-alb" {
  name     = "my-test-alb"
  internal = false
  security_groups = [
    aws_security_group.my-sg["ALB"].id,
  ]
  subnets = [
    aws_subnet.public_subnets[0].id,
    aws_subnet.public_subnets[1].id
  ]
  tags = {
    Name = "my-test-alb"
  }
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Create a Target Group
resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id
}

# Create Listener for Target Group
resource "aws_lb_listener" "my-test-alb-listener" {
  load_balancer_arn = aws_lb.my-aws-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-target-group.arn
  }
}

# Create Internal Application Load Balancer
resource "aws_lb" "my-aws-alb-private" {
  name     = "my-test-alb-private"
  internal = true
  security_groups = [
    aws_security_group.my-sg["ALB"].id,
  ]
  subnets = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id
    
  ]
  tags = {
    Name = "my-test-alb-private"
  }
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

# Create Target Group for Private Servers
resource "aws_lb_target_group" "my-target-group_private" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-private"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.my_vpc.id
}

# Create Listener for Internal Load Balancer
resource "aws_lb_listener" "my-test-alb-listener-private" {
  load_balancer_arn = aws_lb.my-aws-alb-private.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my-target-group_private.arn
  }
}
