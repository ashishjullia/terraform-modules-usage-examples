# VPC
variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "private_subnets_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2
}

variable "public_subnets_count" {
  description = "Number of public subnets"
  type        = number
  default     = 2
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways"
  type        = number
  default     = 0
}

variable "eip_nat_count" {
  description = "Number of Elastic IPs for NAT gateways"
  type        = number
  default     = 0
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["a", "b"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Name prefix for the VPC and related resources"
  type        = string
  default     = "my-vpc"
}

variable "map_public_ip_on_launch_public_subnet" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch_private_subnet" {
  description = "Map public IP on launch for private subnets"
  type        = bool
  default     = false
}


# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "myproject"
    Environment = "dev"
  }
}

# RDS
variable "allocated_storage" {
  description = "The size of the database (in GB)"
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "The storage type for the database"
  type        = string
  default     = "gp2"
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "14.5"
}

variable "instance_class" {
  description = "The class of the database instance"
  type        = string
  default     = "db.t3.medium"
}

variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
  default     = "my-postgres-db"
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

variable "multi_az" {
  description = "Specifies if the database instance is multi-AZ"
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "The number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: \"ddd:hh24:mi-ddd:hh24:mi\". Eg: \"Mon:00:00-Mon:03:00\"."
  type        = string
  default     = "mon:04:00-mon:04:30"
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true. The default is false."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Retention period of Performance Insights data"
  type        = number
  default     = 7
}

variable "db_port" {
  description = "The port the DB listens on"
  type        = number
  default     = 5432
}

variable "db_network_type" {
  description = "The network type of the DB instance. Valid values: IPV4, DUAL."
  type        = string
}

variable "db_ca_identifier" {
  description = "Certificate identifier."
  type        = string
}

variable "database_insights_mode" {
  description = "The mode of Database Insights that is enabled for the instance. Valid values: standard, advanced ."
  type        = string
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported."
  type        = list(string)
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance."
  type        = string
}

variable "copy_tags_to_snapshot" {
  description = "Copy all Instance tags to snapshots. Default is false."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to true."
  type        = bool
  default     = true
}

variable "kms_keys" {
  type = map(object({
    description             = string
    deletion_window_in_days = number
  }))
  default = {
    db_kms = {
      description             = "Database KMS key"
      deletion_window_in_days = 30
    }
    performance_insights_kms = {
      description             = "Performance Insights KMS key"
      deletion_window_in_days = 30
    }
  }
}

variable "db_user_init" {
  description = "Whether to create 1st db iam user or not"
  type        = bool
}

variable "first_db_iam_user" {
  description = "first db iam user name"
  type        = string
}

variable "db_instance_public_access" {
  description = "Whether the db instance is publicly accessible or not."
  type        = bool
  default     = false
}

variable "rds_skip_final_snapshot" {
  description = "rds_skip_final_snapshot"
  type        = bool
}

# Secrets Manager
variable "secrets_metadata" {
  type = map(object({
    secret_name = string
    kms_key     = string
  }))
}

variable "secrets_values" {
  type      = map(map(string))
  sensitive = true
}

variable "secretsmanager_kms_keys" {
  type = map(object({
    description             = string
    deletion_window_in_days = number
  }))
}

# RDS IAM Auth
variable "iam_database_authentication_enabled" {
  description = "iam_database_authentication_enabled"
  type        = bool
  default     = false
}

variable "db_change_apply_immediately" {
  description = "db_change_apply_immediately"
  type        = bool
  default     = false
}


# ECS
variable "name_of_ecs_cluster" {
  description = "name_of_ecs_cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "ecs_service_name"
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

variable "ecs_container_definition_cpu_units" {
  description = "ecs_container_definition_cpu_units"
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

# Load Balancer
variable "aws_lb_target_group_name" {
  description = "aws_lb_target_group_name"
  type        = string
}

variable "health_check_path" {
  description = "Path for the ALB health check"
  type        = string
  default     = "/"
}

# ACM / Cloudflare
variable "app_subdomain" {
  description = "domain_name for app"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The Zone ID for the domain in Cloudflare"
  type        = string
}

variable "record_type" {
  description = "The type of the DNS record (e.g., CNAME)"
  type        = string
}

variable "record_ttl" {
  description = "TTL for the DNS record"
  type        = number
  default     = 60
}

variable "proxied" {
  description = "Whether the record should be proxied by Cloudflare (MUST be false for ACM validation)"
  type        = bool
  default     = false
}

variable "app_zone" {
  description = "app_zone"
  type        = string
}

# VPC Endpoints
variable "interface_endpoint_services" {
  description = "A map of friendly names to AWS service names (without region prefix) for Interface Endpoints to create. Key is arbitrary, value is the service suffix (e.g., 'ec2', 's3', 'logs')."
  type        = map(string)
  default     = {}
}

variable "private_dns_enabled" {
  description = "private_dns_enabled"
  type        = bool
}

# ECR
variable "ecr_repo_name" {
  description = "ecr_repo_name"
  type        = string
}

variable "ecr_repo_image_tag_mutability" {
  description = "ecr_repo_image_tag_mutability"
  type        = string
}

variable "ecr_repo_scan_on_push" {
  description = "ecr_repo_scan_on_push"
  type        = bool
}

# IAM - iam_role_for_init_lambda
variable "iam_role_for_init_lambda_create_role" {
  description = "Whether to create a role"
  type        = bool
  default     = false
}

variable "iam_role_for_init_lambda_role_name" {
  description = "IAM role name"
  type        = string
  default     = null
}

variable "iam_role_for_init_lambda_role_assume_role_policy_data" {
  description = "The data structure for the IAM role's assume role policy."
  type        = any
  default = {
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  }
}

variable "iam_role_for_init_lambda_custom_role_policy_arns" {
  description = "List of ARNs of IAM policies to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "iam_role_for_init_lambda_create_iam_role_inline_policy" {
  description = "Whether to create iam role inline policy or not"
  type        = bool
}

variable "iam_role_for_init_lambda_inline_policy_statements" {
  description = "List of inline policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) to attach to IAM role as an inline policy"
  type        = any
  default     = []
}

# IAM - iam_role_for_ecs_execution_role
variable "iam_role_for_ecs_execution_role_create_role" {
  description = "Whether to create a role"
  type        = bool
  default     = false
}

variable "iam_role_for_ecs_execution_role_role_name" {
  description = "IAM role name"
  type        = string
  default     = null
}

variable "iam_role_for_ecs_execution_role_role_assume_role_policy_data" {
  description = "The data structure for the IAM role's assume role policy."
  type        = any
  default = {
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  }
}

variable "iam_role_for_ecs_execution_role_custom_role_policy_arns" {
  description = "List of ARNs of IAM policies to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "iam_role_for_ecs_execution_role_create_iam_role_inline_policy" {
  description = "Whether to create iam role inline policy or not"
  type        = bool
}

variable "ecs_execution_role_inline_statements" {
  description = "List of inline policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) to attach to IAM role as an inline policy"
  type        = any
  default     = []
}

# IAM - iam_role_for_ecs_task_execution_role
variable "iam_role_for_ecs_task_role_create_role" {
  description = "Whether to create a role"
  type        = bool
  default     = false
}

variable "iam_role_for_ecs_task_role_role_name" {
  description = "IAM role name"
  type        = string
  default     = null
}

variable "iam_role_for_ecs_task_role_role_assume_role_policy_data" {
  description = "The data structure for the IAM role's assume role policy."
  type        = any
  default = {
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  }
}

variable "iam_role_for_ecs_task_role_custom_role_policy_arns" {
  description = "List of ARNs of IAM policies to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "iam_role_for_ecs_task_role_create_iam_role_inline_policy" {
  description = "Whether to create iam role inline policy or not"
  type        = bool
}

variable "ecs_task_role_inline_statements" {
  description = "List of inline policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) to attach to IAM role as an inline policy"
  type        = any
  default     = []
}

# VPC Endpoint
variable "vpc_endpoint_sg_ingress_cidr_blocks" {
  description = "List of CIDR blocks allowed for ingress traffic (HTTPS/443) to the interface endpoints"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "endpoints_config" {
  description = <<-EOT
  A map defining the VPC endpoints to create.
  Each key is an arbitrary friendly name for the endpoint.
  The value is an object with the following attributes:
    - service_name: The service suffix (e.g., 's3', 'ec2', 'kms', 'ecr.api').
    - endpoint_type: The type of endpoint, either "Interface" or "Gateway".
  EOT
  type = map(object({
    service_name  = string
    endpoint_type = string
  }))
  default = {}
  # Example usage from root module:
  # endpoints_config = {
  #   s3 = {
  #     service_name  = "s3"
  #     endpoint_type = "Gateway"
  #   }
  #   kms = {
  #     service_name  = "kms"
  #     endpoint_type = "Interface"
  #   }
  #   secretsmanager = {
  #     service_name  = "secretsmanager"
  #     endpoint_type = "Interface"
  #   }
  #   ecr_api = {
  #     service_name  = "ecr.api"
  #     endpoint_type = "Interface"
  #   }
  #   ecr_dkr = {
  #     service_name  = "ecr.dkr"
  #     endpoint_type = "Interface"
  #   }
  # }
}

variable "interface_endpoint_private_subnet_ids" {
  description = "List of private subnet IDs where the Interface VPC Endpoints will be attached. Required if creating Interface endpoints."
  type        = list(string)
  default     = null
}

variable "gateway_endpoint_route_table_ids" {
  description = "List of Route Table IDs to associate with Gateway VPC Endpoints. Required if creating Gateway endpoints."
  type        = list(string)
  default     = null
}

variable "interface_endpoint_private_dns_enabled" {
  description = "Whether to enable private DNS for the interface endpoints"
  type        = bool
  default     = true
}

variable "interface_endpoint_extra_sg_ids" {
  description = "List of additional Security Group IDs to attach to Interface VPC Endpoints"
  type        = list(string)
  default     = []
}

# SNS
variable "sns_topic_name" {
  description = "sns_topic_name"
  type        = string
}

variable "email_address_for_sns_topic_subscription" {
  description = "email_address_for_sns_topic_subscription"
  type        = string
}

# --- Cloudwatch alarm for rds cpu alarm ---

variable "alarm_name_rds_cpu_alarm" {
  description = "Name for the RDS CPU Utilization High alarm."
  type        = string
}

variable "comparison_operator_rds_cpu_alarm" {
  description = "Comparison operator for the RDS CPU alarm."
  type        = string
}

variable "evaluation_periods_rds_cpu_alarm" {
  description = "Number of periods to evaluate for the RDS CPU alarm."
  type        = number
}

variable "metric_name_rds_cpu_alarm" {
  description = "Metric name for the RDS CPU alarm."
  type        = string
}

variable "namespace_rds_cpu_alarm" {
  description = "Namespace for the RDS CPU alarm metric."
  type        = string
}

variable "period_rds_cpu_alarm" {
  description = "Period in seconds over which to evaluate the RDS CPU alarm metric."
  type        = number
}

variable "statistic_rds_cpu_alarm" {
  description = "Statistic for the RDS CPU alarm metric."
  type        = string
}

variable "threshold_rds_cpu_alarm" {
  description = "Threshold value for the RDS CPU alarm."
  type        = number
}

variable "alarm_description_rds_cpu_alarm" {
  description = "Description for the RDS CPU alarm."
  type        = string
}

# --- Cloudwatch alarm for rds database conn. alarm ---

variable "alarm_name_rds_database_conn_alarm" {
  description = "Name for the RDS Database Connections High alarm."
  type        = string
}

variable "comparison_operator_rds_database_conn_alarm" {
  description = "Comparison operator for the RDS Database Connections alarm."
  type        = string
}

variable "evaluation_periods_rds_database_conn_alarm" {
  description = "Number of periods to evaluate for the RDS Database Connections alarm."
  type        = number
}

variable "metric_name_rds_database_conn_alarm" {
  description = "Metric name for the RDS Database Connections alarm."
  type        = string
}

variable "namespace_rds_database_conn_alarm" {
  description = "Namespace for the RDS Database Connections alarm metric."
  type        = string
}

variable "period_rds_database_conn_alarm" {
  description = "Period in seconds over which to evaluate the RDS Database Connections alarm metric."
  type        = number
}

variable "statistic_rds_database_conn_alarm" {
  description = "Statistic for the RDS Database Connections alarm metric."
  type        = string
}

variable "threshold_rds_database_conn_alarm" {
  description = "Threshold value for the RDS Database Connections alarm."
  type        = number
}

variable "alarm_description_rds_database_conn_alarm" {
  description = "Description for the RDS Database Connections alarm."
  type        = string
}

# --- Cloudwatch alarm for ecs cpu util. alarm ---

variable "alarm_name_ecs_cpu_util_alarm" {
  description = "Name for the ECS Service CPU Utilization High alarm."
  type        = string
}

variable "comparison_operator_ecs_cpu_util_alarm" {
  description = "Comparison operator for the ECS CPU Utilization alarm."
  type        = string
}

variable "evaluation_periods_ecs_cpu_util_alarm" {
  description = "Number of periods to evaluate for the ECS CPU Utilization alarm."
  type        = number
}

variable "metric_name_ecs_cpu_util_alarm" {
  description = "Metric name for the ECS CPU Utilization alarm."
  type        = string
}

variable "namespace_ecs_cpu_util_alarm" {
  description = "Namespace for the ECS CPU Utilization alarm metric."
  type        = string
}

variable "period_ecs_cpu_util_alarm" {
  description = "Period in seconds over which to evaluate the ECS CPU Utilization alarm metric."
  type        = number
}

variable "statistic_ecs_cpu_util_alarm" {
  description = "Statistic for the ECS CPU Utilization alarm metric."
  type        = string
}

variable "threshold_ecs_cpu_util_alarm" {
  description = "Threshold value for the ECS CPU Utilization alarm."
  type        = number
}

variable "alarm_description_ecs_cpu_util_alarm" {
  description = "Description for the ECS CPU Utilization alarm."
  type        = string
}

# --- Cloudwatch alarm for ecs mem util. alarm ---

variable "alarm_name_ecs_mem_util_alarm" {
  description = "Name for the ECS Service Memory Utilization High alarm."
  type        = string
}

variable "comparison_operator_ecs_mem_util_alarm" {
  description = "Comparison operator for the ECS Memory Utilization alarm."
  type        = string
}

variable "evaluation_periods_ecs_mem_util_alarm" {
  description = "Number of periods to evaluate for the ECS Memory Utilization alarm."
  type        = number
}

variable "metric_name_ecs_mem_util_alarm" {
  description = "Metric name for the ECS Memory Utilization alarm."
  type        = string
}

variable "namespace_ecs_mem_util_alarm" {
  description = "Namespace for the ECS Memory Utilization alarm metric."
  type        = string
}

variable "period_ecs_mem_util_alarm" {
  description = "Period in seconds over which to evaluate the ECS Memory Utilization alarm metric."
  type        = number
}

variable "statistic_ecs_mem_util_alarm" {
  description = "Statistic for the ECS Memory Utilization alarm metric."
  type        = string
}

variable "threshold_ecs_mem_util_alarm" {
  description = "Threshold value for the ECS Memory Utilization alarm."
  type        = number
}

variable "alarm_description_ecs_mem_util_alarm" {
  description = "Description for the ECS Memory Utilization alarm."
  type        = string
}
