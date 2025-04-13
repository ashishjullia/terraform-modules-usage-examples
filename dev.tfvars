# VPC
cidr_block                             = "10.0.0.0/16"
enable_dns_hostnames                   = true
enable_dns_support                     = true
private_subnets_count                  = 2
public_subnets_count                   = 2
nat_gateway_count                      = 0
eip_nat_count                          = 0
azs                                    = ["a", "b"]
aws_region                             = "ap-south-1"
vpc_name                               = "dev-vpc"
map_public_ip_on_launch_public_subnet  = true
map_public_ip_on_launch_private_subnet = false

# RDS
allocated_storage                     = 20
storage_type                          = "gp3"
engine                                = "postgres"
engine_version                        = "17.4"
instance_class                        = "db.t4g.micro"
identifier                            = "postgres-db-dev"
db_subnet_group_name                  = "postgres-db-dev-subnet-group"
multi_az                              = true
storage_encrypted                     = true
maintenance_window                    = "sat:05:00-sat:05:30"
performance_insights_enabled          = true
performance_insights_retention_period = 7
rds_skip_final_snapshot               = true
db_network_type                       = "IPV4"
db_ca_identifier                      = "rds-ca-rsa2048-g1"
database_insights_mode                = "standard"
enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade", "iam-db-auth-error"]
db_name                               = "testapprdsdb"
backup_retention_period               = 7
backup_window                         = "01:00-02:00"
copy_tags_to_snapshot                 = true
auto_minor_version_upgrade            = true
deletion_protection                   = false

kms_keys = {
  db_kms = {
    description             = "Custom description for Database KMS key"
    deletion_window_in_days = 15
  }
  performance_insights_kms = {
    description             = "Custom description for Performance Insights KMS key"
    deletion_window_in_days = 20
  }
}

db_port                   = 5432
db_instance_public_access = false

db_user_init      = true
first_db_iam_user = "first_db_user"


# Secrets Manager
secretsmanager_kms_keys = {
  pg_master_creds = {
    description             = "Custom description for pg master creds secrets"
    deletion_window_in_days = 15
  },
  todo_app_creds = {
    description             = "Custom description for todo app creds secrets"
    deletion_window_in_days = 15
  },
}

secrets_metadata = {
  pg_master_creds = {
    secret_name = "pg-master-credentials-secret-v6"
    kms_key     = "pg_master_creds"
  },
  todo_app_creds = {
    secret_name = "nodejs-todo-app-v3"
    kms_key     = "todo_app_creds"
  }
}

secrets_values = {
  pg_master_creds = {
    username = "postgresMaster"
    # Additional sensitive key/value pairs can be added here
  },
  todo_app_creds = {}
}

iam_database_authentication_enabled = true
db_change_apply_immediately         = true


# ECS
name_of_ecs_cluster                     = "dev-cluster-1"
ecs_service_name                        = "sample-ecs-service-nodejs"
ecs_desired_task_count                  = 1 # Just to keep it simple
ecs_task_launch_type                    = "FARGATE"
ecs_task_definition_name                = "sample-ecs-task-definition-nodejs"
ecs_task_definition_network_work        = "awsvpc" # for FARGATE
ecs_task_definition_set_of_launch_types = ["FARGATE"]
ecs_task_definition_cpu_units           = 512  # 0.5 vCPU
ecs_task_definition_memory_units        = 1024 # 1 GB RAM
ecs_container_name                      = "ecs_nodejs_container"
ecs_container_definition_cpu_units      = 512  # 0.5 vCPU
ecs_container_definition_memory_units   = 1024 # 1 GB RAM
ecs_container_definition_container_port = 80
# ecs_container_definition_host_port=80
aws_ecs_service_assign_public_ip = false
# ecs_container_image_uri="254319123211.dkr.ecr.ap-south-1.amazonaws.com/test-repo"
aws_lb_target_group_name = "target-group-nodejs-app"
# aws_lb_target_group_traffic_protocol="HTTP"
# aws_lb_target_group_target_type="ip" # Required for Fargate with awsvpc network mode
# aws_lb_subnet_ids=[""] # if public, make sure to enable "map_public_ip_on_launch_public_subnet=true" in vpc module's var
health_check_path = "/health"


# ACM and Cloudflare
# To create samplenodejsapp.example.com, Cloudflare needs record_name = "samplenodejsapp".
# To create www.example.com, Cloudflare needs record_name = "www".
# app_subdomain="samplenodejsapp"
# root_zone_name_with_dot     = "example.com."
app_subdomain      = "samplenodejsapp"
app_zone           = "example.com"
cloudflare_zone_id = "a4a25390010a323a381d0ca505874b8f"
record_type        = "CNAME"
record_ttl         = 60
proxied            = false

# VPC Endpoint
private_dns_enabled = true
endpoints_config = {
  kms = {
    service_name  = "kms"
    endpoint_type = "Interface"
  }
  secretsmanager = {
    service_name  = "secretsmanager"
    endpoint_type = "Interface"
  }
  ecr_api = {
    service_name  = "ecr.api"
    endpoint_type = "Interface"
  }
  ecr_dkr = {
    service_name  = "ecr.dkr"
    endpoint_type = "Interface"
  }
  s3 = {
    service_name  = "s3"
    endpoint_type = "Gateway"
  }
  logs = {
    service_name  = "logs"
    endpoint_type = "Interface"
  }
}

# interface_endpoint_services = {
#   kms            = "kms"
#   secretsmanager = "secretsmanager"
#   ecr_api        = "ecr.api"
#   ecr_dkr        = "ecr.dkr"
# }

# TAGS
tags = {
  Project     = "myproject"
  Environment = "dev"
}

# ECR
ecr_repo_name                 = "sample-todo-nodejs-pgsql-app"
ecr_repo_image_tag_mutability = "MUTABLE"
ecr_repo_scan_on_push         = true

# IAM - iam_role_for_init_lambda
iam_role_for_init_lambda_create_role = true
iam_role_for_init_lambda_role_name   = "iam_role_for_init_lambda"
iam_role_for_init_lambda_role_assume_role_policy_data = {
  Version = "2012-10-17"
  Statement = [{
    Action    = "sts:AssumeRole"
    Effect    = "Allow"
    Principal = { Service = "lambda.amazonaws.com" }
  }]
}
iam_role_for_init_lambda_custom_role_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
"arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
iam_role_for_init_lambda_create_iam_role_inline_policy = true

# IAM - iam_role_for_ecs_execution_role
iam_role_for_ecs_execution_role_create_role = true
iam_role_for_ecs_execution_role_role_name   = "iam_role_for_ecs_execution_role"
iam_role_for_ecs_execution_role_role_assume_role_policy_data = {
  Version = "2012-10-17"
  Statement = [
    {
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }
  ]
}
iam_role_for_ecs_execution_role_custom_role_policy_arns       = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
iam_role_for_ecs_execution_role_create_iam_role_inline_policy = true
ecs_execution_role_inline_statements                          = []

# IAM - iam_role_for_ecs_task_role
iam_role_for_ecs_task_role_create_role = true
iam_role_for_ecs_task_role_role_name   = "iam_role_for_ecs_task_role"
iam_role_for_ecs_task_role_role_assume_role_policy_data = {
  Version = "2012-10-17"
  Statement : [
    {
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
  ]
}
iam_role_for_ecs_task_role_custom_role_policy_arns       = []
iam_role_for_ecs_task_role_create_iam_role_inline_policy = true
ecs_task_role_inline_statements                          = []

# SNS
sns_topic_name                           = "basic_alerts"
email_address_for_sns_topic_subscription = "example@example.com"

# Cloudwatch alarm for rds cpu alarm
alarm_name_rds_cpu_alarm          = "RDS-CPU-Utilization-High"
comparison_operator_rds_cpu_alarm = "GreaterThanThreshold"
evaluation_periods_rds_cpu_alarm  = 5
metric_name_rds_cpu_alarm         = "CPUUtilization"
namespace_rds_cpu_alarm           = "AWS/RDS"
period_rds_cpu_alarm              = 60
statistic_rds_cpu_alarm           = "Average"
threshold_rds_cpu_alarm           = 80
alarm_description_rds_cpu_alarm   = "Alarm when RDS CPU utilization exceeds 80% for 5 consecutive minutes."
# dimensions_rds_cpu_alarm=
# alarm_actions_rds_cpu_alarm=

# Cloudwatch alarm for rds database conn. alarm
alarm_name_rds_database_conn_alarm          = "RDS-DatabaseConnections-High"
comparison_operator_rds_database_conn_alarm = "GreaterThanThreshold"
evaluation_periods_rds_database_conn_alarm  = 5
metric_name_rds_database_conn_alarm         = "DatabaseConnections"
namespace_rds_database_conn_alarm           = "AWS/RDS"
period_rds_database_conn_alarm              = 60
statistic_rds_database_conn_alarm           = "Average"
threshold_rds_database_conn_alarm           = 100
alarm_description_rds_database_conn_alarm   = "Alarm when the number of database connections exceeds 100 for 5 consecutive minutes."
# dimensions_rds_database_conn_alarm=
# alarm_actions_rds_database_conn_alarm=

# Cloudwatch alarm for ecs cpu util. alarm
alarm_name_ecs_cpu_util_alarm          = "ECS-Service-CPU-Utilization-High"
comparison_operator_ecs_cpu_util_alarm = "GreaterThanThreshold"
evaluation_periods_ecs_cpu_util_alarm  = 5
metric_name_ecs_cpu_util_alarm         = "CPUUtilization"
namespace_ecs_cpu_util_alarm           = "AWS/ECS"
period_ecs_cpu_util_alarm              = 60
statistic_ecs_cpu_util_alarm           = "Average"
threshold_ecs_cpu_util_alarm           = 80
alarm_description_ecs_cpu_util_alarm   = "Alarm when ECS service CPU utilization exceeds 80% for 5 consecutive minutes."
# dimensions_ecs_cpu_util_alarm=
# alarm_actions_ecs_cpu_util_alarm=

# Cloudwatch alarm for ecs mem util. alarm
alarm_name_ecs_mem_util_alarm          = "ECS-Service-Memory-Utilization-High"
comparison_operator_ecs_mem_util_alarm = "GreaterThanThreshold"
evaluation_periods_ecs_mem_util_alarm  = 5
metric_name_ecs_mem_util_alarm         = "MemoryUtilization"
namespace_ecs_mem_util_alarm           = "AWS/ECS"
period_ecs_mem_util_alarm              = 60
statistic_ecs_mem_util_alarm           = "Average"
threshold_ecs_mem_util_alarm           = 80
alarm_description_ecs_mem_util_alarm   = "Alarm when ECS service memory utilization exceeds 80% for 5 consecutive minutes."
# dimensions_ecs_cpu_util_alarm=
# alarm_actions_ecs_cpu_util_alarm=
