variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "" 
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "aws_ecs_service_subnet_ids" {
  description = "List of subnet IDs (at least two in different AZs) for ALB and Fargate tasks"
  type        = list(string)
  # Example: ["subnet-012345abc", "subnet-067890def"]
  # These should ideally be private subnets with NAT Gateway/VPC Endpoint access
  # Using public subnets here for simplicity - requires assign_public_ip = true
}

variable "environment_variables" {
  description = "A map of environment variables for the container"
  type        = map(string)
  default     = {}
  # Example: { NODE_ENV = "production", API_KEY = "some_secret_value" }
  # Consider using AWS Secrets Manager or Parameter Store for secrets!
}

variable "container_secrets" {
  description = "A map of secrets to fetch from AWS Secrets Manager or Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string # ARN of the secret in Secrets Manager or Parameter Store
  }))
  default = []
  # Example:
  # [
  #   { name = "DATABASE_PASSWORD", valueFrom = "arn:aws:secretsmanager:us-east-1:123456789012:secret:my-db-secret-abcdef" },
  #   { name = "API_KEY", valueFrom = "arn:aws:ssm:us-east-1:123456789012:parameter/my-api-key"}
  # ]
}


variable "name_of_ecs_cluster" {
  description = "name_of_ecs_cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "name_of_ecs_cluster" # Note: description seems copied, might want to update
  type        = string
}

variable "ecs_desired_task_count" {
  description = "ecs_desired_task_count"
  type        = string
}

variable "ecs_task_launch_type" {
  description = "ecs_task_launch_type"
  type        = string
}

variable "ecs_task_definition_name" {
  description = "ecs_task_definition_name"
  type        = string
}

variable "ecs_task_definition_network_work" {
  description = "ecs_task_definition_network_work"
  type        = string
}

variable "ecs_task_definition_set_of_launch_types" {
  description = "ecs_task_definition_set_of_launch_types"
  type        = list(string)
}

variable "ecs_task_definition_cpu_units" {
  description = "ecs_task_definition_cpu_units"
  type        = number
}

variable "ecs_task_definition_memory_units" {
  description = "ecs_task_definition_memory_units"
  type        = number
}

variable "ecs_container_name" {
  description = "ecs_container_name"
  type        = string
}

variable "ecs_container_image_uri" {
  description = "ecs_container_image_uri"
  type        = string
}

variable "ecs_container_definition_cpu_units" {
  description = "ecs_container_cpu_units" # Note: description was slightly different, fixed based on var name
  type        = number
}

variable "ecs_container_definition_memory_units" {
  description = "ecs_container_definition_memory_units"
  type        = number
}

variable "ecs_container_definition_container_port" {
  description = "ecs_container_definition_container_port"
  type        = number
}

variable "aws_ecs_service_assign_public_ip" {
  description = "aws_ecs_service_assign_public_ip"
  type        = bool
}

variable "alb_target_group_arn" {
  description = "alb_target_group_arn"
  type        = string
}

variable "alb_security_group" {
  description = "alb_security_group"
  type        = list(string)
}

variable "ecs_execution_role_arn" {
  description = "ecs_execution_role_arn"
  type = string
}
