output "ecs_cluster_name" {
  description = "The name of the created ECS Cluster."
  value       = aws_ecs_cluster.app_cluster.name
}

output "ecs_service_name" {
  description = "The name of the created ECS Service."
  value       = aws_ecs_service.app_service.name
}

output "ecs_tasks_security_group_id" {
  description = "The ID of the Security Group created for the ECS tasks."
  value       = aws_security_group.ecs_tasks_sg.id
}

output "ecs_task_definition_family_name" {
  description = "ecs_task_definition_family_name"
  value       = aws_ecs_task_definition.app_nodejs_task_definition.family
}
