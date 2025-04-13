locals {
  lambda_source_file_name = "index.js"
  lambda_package_script_name = "package_lambda.sh"

  lambda_source_and_build_dir = abspath("${path.module}/intermediate/build")
  lambda_source_file_path     = "${local.lambda_source_and_build_dir}/${local.lambda_source_file_name}"
  # lambda_package_script_path  = abspath("${local.lambda_source_and_build_dir}/${local.lambda_package_script_name}")
  lambda_to_upload_dir        = abspath("${path.module}/intermediate/to_upload")
  lambda_zip_filename         = "create_rds_pg_user_lambda.zip"
  lambda_zip_path             = "${local.lambda_to_upload_dir}/${local.lambda_zip_filename}"
}

# resource "null_resource" "package_lambda_function" {
#   triggers = {
#     code_sha   = filesha256(local.lambda_source_file_path)
#     script_sha = filesha256(local.lambda_package_script_path)
#   }

#   provisioner "local-exec" {
#     command = "/bin/bash -e \"${local.lambda_package_script_path}\" \"${local.lambda_source_and_build_dir}\""
#   }
# }

data "archive_file" "lambda_package_zip" {
  type        = "zip"
  source_dir  = local.lambda_source_and_build_dir
  output_path = local.lambda_zip_path
  excludes = [
    "package.json",
    "package-lock.json",
    local.lambda_package_script_name
    ]

  # depends_on = [null_resource.package_lambda_function]
}

resource "aws_lambda_function" "init_db_user_lambda_function" {
  count = var.db_user_init ? 1 : 0

  function_name = "init-lambda-for-${var.identifier}-dbuser-${var.db_name}"
  description   = "Initializes the first IAM database user for RDS instance ${var.identifier}"
  runtime       = "nodejs18.x"
  handler       = "index.handler"
  timeout       = 60
  memory_size   = 128

  filename         = data.archive_file.lambda_package_zip.output_path
  source_code_hash = data.archive_file.lambda_package_zip.output_base64sha256

  # role = aws_iam_role.lambda_db_init_role[0].arn
  role = var.init_db_user_lambda_function_role_arn
  architectures = ["x86_64"]

  vpc_config {
    subnet_ids         = var.private_subnet_id_for_init_lambda
    security_group_ids = [aws_security_group.default_db_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.db_instance.address
      DB_NAME     = aws_db_instance.db_instance.db_name
      SECRET_NAME = var.master_secret_name_for_lambda_function
      IAM_USER    = var.first_db_iam_user
    }
  }

  depends_on = [
    aws_db_instance.db_instance,
    # aws_iam_role_policy_attachment.lambda_logs,
    # aws_iam_role_policy_attachment.lambda_vpc_access,
    # aws_iam_role_policy.lambda_secret_access,
    data.archive_file.lambda_package_zip
  ]
}

resource "aws_db_instance" "db_instance" {
  allocated_storage                     = var.allocated_storage
  storage_type                          = var.storage_type
  engine                                = var.engine
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  identifier                            = var.identifier
  username                              = var.username
  password                              = var.password
  db_subnet_group_name                  = aws_db_subnet_group.db_subnet_group.name
  multi_az                              = var.multi_az
  storage_encrypted                     = var.storage_encrypted
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.backup_window
  maintenance_window                    = var.maintenance_window
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = try(aws_kms_key.kms["performance_insights_kms"].arn, null)
  performance_insights_retention_period = var.performance_insights_retention_period
  skip_final_snapshot                   = var.skip_final_snapshot
  publicly_accessible                   = var.db_instance_public_access
  kms_key_id                            = try(aws_kms_key.kms["db_kms"].arn, null)
  vpc_security_group_ids                = [aws_security_group.default_db_sg.id]
  network_type                          = var.db_network_type
  ca_cert_identifier                    = var.db_ca_identifier != null ? aws_rds_certificate.db_ca_id[0].certificate_identifier : null
  database_insights_mode                = var.database_insights_mode
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  db_name                               = var.db_name
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  auto_minor_version_upgrade            = var.auto_minor_version_upgrade
  deletion_protection                   = var.deletion_protection
  iam_database_authentication_enabled   = var.iam_database_authentication_enabled
  apply_immediately                     = var.db_change_apply_immediately

  depends_on = [
    aws_rds_certificate.db_ca_id
  ]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.db_subnet_group_name
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "default_db_sg" {
  name        = "${var.identifier}-db-sg"
  description = "Security Group for ${var.identifier} DB instance"
  vpc_id      = var.vpc_id


  ingress {
    description = "Allow all inbound from private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/24", "10.0.1.0/24"]
  }

  ingress {
    description = "Allow traffic from self (e.g., Lambda)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_kms_key" "kms" {
  for_each                = var.kms_keys
  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
  enable_key_rotation     = true
}

resource "aws_rds_certificate" "db_ca_id" {
  count = var.db_ca_identifier != null ? 1 : 0

  certificate_identifier = var.db_ca_identifier
}

resource "aws_lambda_invocation" "invoke_init_db_user_lambda" {
  count = var.db_user_init ? 1 : 0

  function_name = aws_lambda_function.init_db_user_lambda_function[0].function_name
  input         = jsonencode({})

  # This ensures re-invocation happens whenever the Lambda function's
  # source code hash changes (meaning new code was deployed) OR
  # when the database address changes.
  triggers = {
    lambda_source_hash = aws_lambda_function.init_db_user_lambda_function[0].source_code_hash
    db_address         = aws_db_instance.db_instance.address
  }

  depends_on = [aws_lambda_function.init_db_user_lambda_function]
}
