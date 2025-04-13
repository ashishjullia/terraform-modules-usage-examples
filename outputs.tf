output "debug_validation_fqdns_list" {
  description = "Shows the list of FQDNs being passed to aws_acm_certificate_validation"
  value       = local.validation_fqdns
}

output "debug_validation_record_names_from_module_instances" {
  description = "Shows the raw 'name' output from each cloudflare_validation_records instance"
  value       = { for k, instance in module.cloudflare_validation_records : k => instance.name }
}

output "ecs_cluster_name" {
  description = "The name of the created ECS Cluster."
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "The name of the created ECS Service."
  value       = module.ecs.ecs_service_name
}

output "ecr_repo_name" {
  description = "The name of the created ECR repo"
  value       = module.create_ecr_for_nodejs_app.ecr_repo_name
}

output "db_rds_hostname" {
  description = "db_rds_hostname"
  value       = module.rds.db_rds_hostname
}

output "db_resource_id" {
  description = "db identifier"
  value       = module.rds.db_resource_id
}

output "rds_arn_resource_id" {
  description = "yo"
  value       = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.rds.db_resource_id}/${var.first_db_iam_user}"
}

output "ecs_task_definition_family_name" {
  description = "ecs_task_definition_family_name"
  value       = module.ecs.ecs_task_definition_family_name
}
