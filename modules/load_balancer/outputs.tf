output "alb_security_group_id" {
  description = "The ID of the security group attached to the ALB."
  value       = aws_security_group.alb_sg.id
}

output "alb_target_group_arn" {
  description = "The ARN of the default target group."
  value       = aws_lb_target_group.main.arn
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (to be used in a Route 53 Alias record)."
  value       = aws_lb.main.zone_id
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS listener."
  value       = aws_lb_listener.https.arn
}

output "http_listener_arn" {
  description = "The ARN of the HTTP redirect listener (if created)."
  value       = try(aws_lb_listener.http_redirect[0].arn, null) # Use try for conditional resource
}
