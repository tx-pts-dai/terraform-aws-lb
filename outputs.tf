output "load_balancer_dns_name" {
  description = "The DNS of the load balancer."
  value       = aws_lb.app.dns_name
}

output "load_balancer_arn_suffix" {
  description = "The ARN suffix of the load balancer."
  value       = aws_lb.app.arn_suffix
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer."
  value       = aws_lb.app.arn
}

output "path_target_groups_arn" {
  description = "Path base routed TG arn"
  value       = { for tg in aws_lb_target_group.path : tg.name => tg.arn }
}

output "default_target_group_arn" {
  description = "Default TG arn"
  value       = aws_lb_target_group.default.arn
}

output "security_group_id" {
  description = "The security group ID linked to the load balancer"
  value       = aws_security_group.alb.id
}
