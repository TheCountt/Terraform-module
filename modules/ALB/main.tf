/// Resources for Nginx Reverse Proxy

# Create a External(Internet-Facing) Load Balancer
resource "aws_lb" "terraform-external-alb" {
  name     = "terraform-external-alb"
  internal = false
  security_groups = [var.public-sg]
  subnets = [var.public-sbn-1, var.public-sbn-2]

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
  subnets = [var.private-sbn-1, var.private-sbn-2]

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





