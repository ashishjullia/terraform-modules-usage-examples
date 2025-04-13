data "aws_caller_identity" "current" {}

resource "random_password" "master_pwd" {
  length           = 16
  special          = true
  override_special = "!#$%&*()_+-=" # allowed special chars (optional customization)
}

locals {
  combined_secrets_values = merge(
    var.secrets_values,
    {
      pg_master_creds = merge(
        lookup(var.secrets_values, "pg_master_creds", {}),
        { password = random_password.master_pwd.result }
      )
    }
  )

  rds_master_secret_name     = var.secrets_metadata["pg_master_creds"]["secret_name"]
  rds_master_kms_key_ref     = var.secrets_metadata["pg_master_creds"]["kms_key"]
  todo_app_creds_secret_name = var.secrets_metadata["todo_app_creds"]["secret_name"]
  todo_app_creds_kms_key_ref = var.secrets_metadata["todo_app_creds"]["kms_key"]
}

#----------------------------------
# VPC Module
#----------------------------------
module "vpc" {
  source = "./modules/vpc"

  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  private_subnets_count = var.private_subnets_count
  public_subnets_count  = var.public_subnets_count
  nat_gateway_count     = var.nat_gateway_count
  eip_nat_count         = var.eip_nat_count
  azs                   = var.azs
  aws_region            = var.aws_region
  vpc_name              = var.vpc_name

  map_public_ip_on_launch_public_subnet  = var.map_public_ip_on_launch_public_subnet
  map_public_ip_on_launch_private_subnet = var.map_public_ip_on_launch_private_subnet

  tags = var.tags
}

#----------------------------------
# VPC Endpoints Module
#----------------------------------
module "vpc_endpoints" {
  source                              = "./modules/vpc_endpoint"
  vpc_id                              = module.vpc.vpc_id
  vpc_endpoint_sg_ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  endpoints_config                    = var.endpoints_config

  aws_region                             = var.aws_region
  interface_endpoint_private_subnet_ids  = [module.vpc.private_subnet_ids[0]]
  interface_endpoint_private_dns_enabled = var.private_dns_enabled
  interface_endpoint_extra_sg_ids        = [module.ecs.ecs_tasks_security_group_id]
  gateway_endpoint_route_table_ids       = module.vpc.private_route_table_ids
}

#----------------------------------
# Secrets Manager Module
#----------------------------------
module "secretsmanager" {
  source = "./modules/secretsmanager"

  secrets_metadata        = var.secrets_metadata
  secretsmanager_kms_keys = var.secretsmanager_kms_keys
  secrets_values          = local.combined_secrets_values
}

#----------------------------------
# RDS Module
#----------------------------------

module "rds" {
  source = "./modules/rds"

  allocated_storage                     = var.allocated_storage
  storage_type                          = var.storage_type
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  identifier                            = var.identifier
  username                              = var.secrets_values["pg_master_creds"]["username"]
  password                              = random_password.master_pwd.result
  multi_az                              = var.multi_az # AWS will automatically select one of the subnets from the DB subnet group for the instance. Because we have multi_az to true, AWS will provision a standby instance in the other subnet for high availability.
  storage_encrypted                     = var.storage_encrypted
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  maintenance_window                    = var.maintenance_window
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  skip_final_snapshot                   = var.rds_skip_final_snapshot
  db_instance_public_access             = var.db_instance_public_access
  db_network_type                       = var.db_network_type
  db_ca_identifier                      = var.db_ca_identifier
  database_insights_mode                = var.database_insights_mode
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  db_name                               = var.db_name
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  deletion_protection                   = var.deletion_protection

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  db_change_apply_immediately         = var.db_change_apply_immediately

  private_subnet_ids                = module.vpc.private_subnet_ids
  private_subnet_id_for_init_lambda = [module.vpc.private_subnet_ids[0]]
  db_subnet_group_name              = var.db_subnet_group_name

  vpc_id = module.vpc.vpc_id

  kms_keys                               = var.kms_keys
  db_user_init                           = var.db_user_init
  first_db_iam_user                      = var.first_db_iam_user
  master_secret_lambda_function_arn      = module.secretsmanager.secret_arns[local.rds_master_secret_name]
  master_secret_name_for_lambda_function = module.secretsmanager.secret_names[local.rds_master_secret_name]
  master_secret_pg_kms_key_arn           = module.secretsmanager.kms_key_arns[local.rds_master_kms_key_ref]

  init_db_user_lambda_function_role_arn = module.iam_role_for_init_lambda.iam_role_arn
}

# The following handles automatic public cert provisioning and attaching of the same to aws external LB for the specified domain
#----------------------------------
# ACM Certificate Request Module
#----------------------------------
# 1. Request the ACM Certificate
module "acm_request" {
  source = "./modules/acm"

  domain_name = "${var.app_subdomain}.${var.app_zone}"
}

#----------------------------------
# Cloudflare DNS Validation Records Module (using for_each)
#----------------------------------
# 2. Create Cloudflare DNS Validation Records (one per validation option)
# Depends on module.acm_request for the for_each input.
module "cloudflare_validation_records" {
  source = "./modules/cloudflare"
  # This iterates over data provided BY AWS ACM.
  # each.value will contain things like:
  #   resource_record_name = "_abc123xyz.samplenodejsapp.example.com"
  #   resource_record_type = "CNAME"
  #   resource_record_value = "_uniquevalueprovidedbyacm.acm-validations.aws."
  # for_each = module.acm_request.domain_validation_options # Iterates over ACM validation CNAMEs
  for_each = local.acm_validation_options_map

  cloudflare_zone_id = var.cloudflare_zone_id

  # Extracts the relative record name (e.g., _uuidpart.subdomain) from the FQDN provided by ACM
  # Requires var.root_zone_name_with_dot (e.g., "example.com.") to be correctly defined.
  # record_name        = replace(each.value.resource_record_name, var.root_zone_name_with_dot, "")

  # Input: each.value.resource_record_name (e.g., "_abc123xyz.samplenodejsapp.example.com")
  # Need: Relative name for Cloudflare (e.g., "_abc123xyz.samplenodejsapp")
  # record_name = replace(each.value.resource_record_name, ".${var.app_zone}", "")
  record_name = trim(replace(each.value.resource_record_name, ".${var.app_zone}", ""), ".")
  record_type = each.value.resource_record_type

  # Pass the dynamic value from ACM using the module's 'record_content' variable name
  # Pass the dynamic value and type from ACM output
  # content     = each.value.resource_record_value # *** Use matching variable name ***
  content    = each.value.resource_record_value
  record_ttl = var.record_ttl
  proxied    = var.proxied
}

#----------------------------------
# Collect FQDNs for ACM Validation
#----------------------------------
# 3. Collect the FQDNs of the created Cloudflare records
# locals {
#   # Collects the fully qualified domain names of the created validation records.
#   # Assumes the cloudflare module outputs 'record_fqdn'.
#   validation_fqdns = [for record in module.cloudflare_validation_records : record.record_fqdn]
# }
locals {
  # Transform the set of validation options into a map keyed by the domain name
  # This assumes each domain in the certificate requires only one validation record,
  # which is typical for DNS CNAME validation.
  acm_validation_options_map = {
    for option in module.acm_request.domain_validation_options : option.domain_name => option
  }

  # Update how validation_fqdns are collected if the module output name changes or needs adjustment
  # Assuming the cloudflare module still outputs 'record_fqdn' even when instantiated via map for_each
  validation_fqdns = [
    # iterate over the instances of the module created by for_each
    for instance in module.cloudflare_validation_records :
    # Combine the relative name output by the module with the known zone name
    "${instance.name}.${var.app_zone}" # Assuming module outputs 'name' (the relative name)
  ]
  # Using this to bypass the known bug
  # validation_fqdns = [
  #     for instance in module.cloudflare_validation_records : instance.name
  #   ]
}

#----------------------------------
# ACM Certificate Validation Resource
#----------------------------------
# 4. Define the ACM Validation Resource (in the parent module)
# This resource tells AWS to check for the DNS records specified in `validation_record_fqdns`. Terraform waits for this resource to complete (i.e., validation successful) before proceeding with resources that depend on it (like the ALB listener using the certificate). This *automates* the waiting-for-validation step.
# Depends on module.acm_request (for ARN) and implicitly on module.cloudflare_validation_records (via local.validation_fqdns).
resource "aws_acm_certificate_validation" "cert_validation_complete" {
  certificate_arn         = module.acm_request.certificate_arn
  validation_record_fqdns = local.validation_fqdns

  timeouts {
    create = "15m" # Adjust if needed
  }
}

#----------------------------------
# Load Balancer Module
#----------------------------------
module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id              = module.vpc.vpc_id
  lb_subnet_ids       = module.vpc.public_subnet_ids
  target_group_name   = var.aws_lb_target_group_name                # Name for TG
  target_group_port   = var.ecs_container_definition_container_port # Port container listens on
  health_check_path   = var.health_check_path
  acm_certificate_arn = module.acm_request.certificate_arn
}


#----------------------------------
# Cloudflare Application DNS Record Module
#----------------------------------
module "cloudflare_app_record" {
  source = "./modules/cloudflare" # Reuse the same module

  cloudflare_zone_id = var.cloudflare_zone_id
  record_name        = var.app_subdomain
  content            = module.load_balancer.alb_dns_name # Point to the ALB's DNS name
  record_type        = var.record_type
  record_ttl         = var.record_ttl
  proxied            = var.proxied
}

#----------------------------------
# ECS Module
#----------------------------------
module "ecs" {
  source = "./modules/ecs"

  vpc_id                                  = module.vpc.vpc_id
  name_of_ecs_cluster                     = var.name_of_ecs_cluster
  ecs_service_name                        = var.ecs_service_name
  ecs_desired_task_count                  = var.ecs_desired_task_count
  ecs_task_launch_type                    = var.ecs_task_launch_type
  aws_ecs_service_subnet_ids              = module.vpc.private_subnet_ids
  aws_ecs_service_assign_public_ip        = var.aws_ecs_service_assign_public_ip
  alb_target_group_arn                    = module.load_balancer.alb_target_group_arn
  ecs_container_name                      = var.ecs_container_name
  ecs_container_definition_container_port = var.ecs_container_definition_container_port
  ecs_task_definition_name                = var.ecs_task_definition_name
  ecs_task_definition_network_work        = var.ecs_task_definition_network_work
  ecs_task_definition_set_of_launch_types = var.ecs_task_definition_set_of_launch_types
  ecs_task_definition_cpu_units           = var.ecs_task_definition_cpu_units
  ecs_task_definition_memory_units        = var.ecs_task_definition_memory_units
  ecs_container_image_uri                 = module.create_ecr_for_nodejs_app.ecr_repo_uri
  aws_region                              = var.aws_region
  ecs_container_definition_cpu_units      = var.ecs_container_definition_cpu_units
  ecs_container_definition_memory_units   = var.ecs_container_definition_memory_units
  alb_security_group                      = [module.load_balancer.alb_security_group_id]
  ecs_execution_role_arn                  = module.iam_role_for_ecs_execution_role.iam_role_arn
}

#----------------------------------
# ECR Module
#----------------------------------
module "create_ecr_for_nodejs_app" {
  source = "./modules/ecr"

  ecr_repo_name                 = var.ecr_repo_name
  ecr_repo_image_tag_mutability = var.ecr_repo_image_tag_mutability
  ecr_repo_scan_on_push         = var.ecr_repo_scan_on_push
}

#----------------------------------
# IAM Module call for init Lambda
#----------------------------------
locals {
  init_lambda_inline_statements = [
    {
      sid       = "AllowSecretRead"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.secretsmanager.secret_arns[local.rds_master_secret_name]]
    },
    {
      sid       = "AllowKMSDecryptForSecret"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.secretsmanager.kms_key_arns[local.rds_master_kms_key_ref]]
    }
  ]
}

module "iam_role_for_init_lambda" {
  source = "./modules/iam"

  create_role                   = var.db_user_init
  role_name                     = var.iam_role_for_init_lambda_role_name
  role_assume_role_policy_data  = var.iam_role_for_init_lambda_role_assume_role_policy_data
  custom_role_policy_arns       = var.iam_role_for_init_lambda_custom_role_policy_arns
  create_iam_role_inline_policy = var.db_user_init
  inline_policy_statements      = local.init_lambda_inline_statements
}

#---------------------------------------
# IAM Module call for ecs execution role
#---------------------------------------
locals {
  iam_role_for_ecs_execution_role_inline_statements = [
    {
      sid       = "AllowSecretRead"
      effect    = "Allow"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = [module.secretsmanager.secret_arns[local.todo_app_creds_secret_name]]
    },
    {
      sid       = "AllowKMSDecryptForSecret"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = [module.secretsmanager.kms_key_arns[local.todo_app_creds_kms_key_ref]]
  }]
}

module "iam_role_for_ecs_execution_role" {
  source = "./modules/iam"

  create_role                   = var.iam_role_for_ecs_execution_role_create_role
  role_name                     = var.iam_role_for_ecs_execution_role_role_name
  role_assume_role_policy_data  = var.iam_role_for_ecs_execution_role_role_assume_role_policy_data
  custom_role_policy_arns       = var.iam_role_for_ecs_execution_role_custom_role_policy_arns
  create_iam_role_inline_policy = var.iam_role_for_ecs_execution_role_create_iam_role_inline_policy
  inline_policy_statements      = local.iam_role_for_ecs_execution_role_inline_statements
}

#--------------------------------------------
# IAM Module call for ecs task execution role
#--------------------------------------------
locals {
  rds_arn_with_resource_id = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${module.rds.db_resource_id}/${var.first_db_iam_user}"

  iam_role_for_ecs_task_role_inline_statements = [
    {
      sid       = "iamrdsauth"
      effect    = "Allow"
      actions   = ["rds-db:connect"]
      resources = [local.rds_arn_with_resource_id]
    }
  ]
}

module "iam_role_for_ecs_task_role" {
  source = "./modules/iam"

  create_role                   = var.iam_role_for_ecs_task_role_create_role
  role_name                     = var.iam_role_for_ecs_task_role_role_name
  role_assume_role_policy_data  = var.iam_role_for_ecs_task_role_role_assume_role_policy_data
  custom_role_policy_arns       = var.iam_role_for_ecs_task_role_custom_role_policy_arns
  create_iam_role_inline_policy = var.iam_role_for_ecs_task_role_create_iam_role_inline_policy
  inline_policy_statements      = local.iam_role_for_ecs_task_role_inline_statements
}

#--------------------------------------------
# SNS Module
#--------------------------------------------
module "sns_topic" {
  source = "./modules/sns"

  sns_topic_name = var.sns_topic_name
  email_address  = var.email_address_for_sns_topic_subscription
}

#--------------------------------------------
# Cloudwatch Module for rds cpu alarm
#--------------------------------------------
module "rds_cpu_alarm" {
  source = "./modules/cloudwatch_alarm"

  alarm_name          = var.alarm_name_rds_cpu_alarm
  comparison_operator = var.comparison_operator_rds_cpu_alarm
  evaluation_periods  = var.evaluation_periods_rds_cpu_alarm
  metric_name         = var.metric_name_rds_cpu_alarm
  namespace           = var.namespace_rds_cpu_alarm
  period              = var.period_rds_cpu_alarm
  statistic           = var.statistic_rds_cpu_alarm
  threshold           = var.threshold_rds_cpu_alarm
  alarm_description   = var.alarm_description_rds_cpu_alarm
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
  alarm_actions = [module.sns_topic.arn]
}

#----------------------------------------------
# Cloudwatch Module for rds database conn. alarm
#-----------------------------------------------
module "rds_database_conn_alarm" {
  source = "./modules/cloudwatch_alarm"

  alarm_name          = var.alarm_name_rds_database_conn_alarm
  comparison_operator = var.comparison_operator_rds_database_conn_alarm
  evaluation_periods  = var.evaluation_periods_rds_database_conn_alarm
  metric_name         = var.metric_name_rds_database_conn_alarm
  namespace           = var.namespace_rds_database_conn_alarm
  period              = var.period_rds_database_conn_alarm
  statistic           = var.statistic_rds_database_conn_alarm
  threshold           = var.threshold_rds_database_conn_alarm
  alarm_description   = var.alarm_description_rds_database_conn_alarm
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
  alarm_actions = [module.sns_topic.arn]
}

#--------------------------------------------
# Cloudwatch Module for ecs cpu util. alarm
#--------------------------------------------
module "ecs_cpu_util_alarm" {
  source = "./modules/cloudwatch_alarm"

  alarm_name          = var.alarm_name_ecs_cpu_util_alarm
  comparison_operator = var.comparison_operator_ecs_cpu_util_alarm
  evaluation_periods  = var.evaluation_periods_ecs_cpu_util_alarm
  metric_name         = var.metric_name_ecs_cpu_util_alarm
  namespace           = var.namespace_ecs_cpu_util_alarm
  period              = var.period_ecs_cpu_util_alarm
  statistic           = var.statistic_ecs_cpu_util_alarm
  threshold           = var.threshold_ecs_cpu_util_alarm
  alarm_description   = var.alarm_description_ecs_cpu_util_alarm
  dimensions = {
    ClusterName = var.name_of_ecs_cluster
    ServiceName = var.ecs_service_name
  }
  alarm_actions = [module.sns_topic.arn]
}

#--------------------------------------------
# Cloudwatch Module for ecs mem util. alarm
#--------------------------------------------
module "ecs_mem_util_alarm" {
  source = "./modules/cloudwatch_alarm"

  alarm_name          = var.alarm_name_ecs_mem_util_alarm
  comparison_operator = var.comparison_operator_ecs_mem_util_alarm
  evaluation_periods  = var.evaluation_periods_ecs_mem_util_alarm
  metric_name         = var.metric_name_ecs_mem_util_alarm
  namespace           = var.namespace_ecs_mem_util_alarm
  period              = var.period_ecs_mem_util_alarm
  statistic           = var.statistic_ecs_mem_util_alarm
  threshold           = var.threshold_ecs_mem_util_alarm
  alarm_description   = var.alarm_description_ecs_mem_util_alarm
  dimensions = {
    ClusterName = var.name_of_ecs_cluster
    ServiceName = var.ecs_service_name
  }
  alarm_actions = [module.sns_topic.arn]
}
