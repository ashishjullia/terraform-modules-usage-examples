output "db_resource_id" {
  description = "db identifier"
  value = aws_db_instance.db_instance.resource_id
}

output "db_rds_hostname" {
  description = "db identifier"
  value = aws_db_instance.db_instance.address
}

output "db_instance_identifier" {
  description = "db_instance_identifier"
  value = aws_db_instance.db_instance.identifier
}
