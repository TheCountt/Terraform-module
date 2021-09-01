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


