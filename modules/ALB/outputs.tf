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