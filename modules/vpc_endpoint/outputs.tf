output "vpc_endpoint_security_group_id" {
  description = "The ID of the Security Group created for VPC Endpoints"
  value       = aws_security_group.vpc_endpoint_sg[0].id
}
