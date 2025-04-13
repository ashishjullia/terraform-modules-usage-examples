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

 variable "username" {
   description = "Database username"
   type        = string
   sensitive   = true
 }

 variable "password" {
   description = "Database password"
   type        = string
   sensitive   = true
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

 variable "enabled_cloudwatch_logs_exports" {
   description = "Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported."
   type        = list(string)
 }

 variable "performance_insights_retention_period" {
   description = "Retention period of Performance Insights data"
   type        = number
   default     = 7
 }

 variable "db_subnet_group_name" {
   description = "The name of the DB subnet group"
   type        = string
 }

 variable "private_subnet_ids" {
   description = "List of private subnet IDs"
   type        = list(string)
 }

 variable "vpc_id" {
   description = "The ID of the VPC"
   type        = string
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

 variable "db_name" {
   description = "The name of the database to create when the DB instance is created. If this parameter is not specified, no database is created in the DB instance."
   type        = string
 }

 variable "copy_tags_to_snapshot" {
   description = "Copy all Instance tags to snapshots. Default is false."
   type        = bool
   default = false
 }

 variable "auto_minor_version_upgrade" {
   description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Defaults to true."
   type        = bool
   default = true
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

 variable "db_instance_public_access" {
   description = "Whether the db instance is publicly accessible or not."
   type        = bool
   default     = false
 }

 variable "db_user_init" {
   description = "Whether to create 1st db iam user or not"
   type        = bool
 }

 variable "master_secret_lambda_function_arn" {
   description = "init lambda function arn"
   type        = string
 }

 variable "master_secret_name_for_lambda_function" {
   description = "init lambda function name"
   type        = string
 }

 variable "first_db_iam_user" {
   description = "first db iam user name"
   type        = string
 }

 variable "master_secret_pg_kms_key_arn" {
   description = "master_secret_pg_kms_key_arn"
   type        = string
 }

 variable "iam_database_authentication_enabled" {
   description = "iam_database_authentication_enabled"
   type        = bool
   default = false
 }

 variable "db_change_apply_immediately" {
   description = "db_change_apply_immediately"
   type        = bool
   default = false
 }

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier."
  type        = bool
  default     = true
}

variable "private_subnet_id_for_init_lambda" {
 description = "private_subnet_id_for_init_lambda"
 type =  list(string)
}

variable "init_db_user_lambda_function_role_arn" {
  description = "init_db_user_lambda_function_role_arn"
  type      = string
}
