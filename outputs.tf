output "load_balancer_dns_name" {
  description = "The DNS of the load balancer."
  value       = aws_lb.app.dns_name
}

output "load_balancer_arn_suffix" {
  description = "The ARN suffix of the load balancer."
  value       = aws_lb.app.arn_suffix
}

output "load_balancer_arn" {
  description = "The ARN sffix of the load balancer."
  value       = aws_lb.app.arn
}


output "target_group_arns" {
  description = "A list of ARNs for all target groups associated with the load balancer."
  value       = aws_lb_target_group.app[*].arn
}

output "target_group_arns_suffix" {
  description = "A list of ARNs suffix for all target groups associated with the load balancer."
  value       = aws_lb_target_group.app[*].arn_suffix
}
