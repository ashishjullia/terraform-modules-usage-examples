output "secret_arns" {
  description = "Mapping of secret names to ARNs"
  value = { for s in aws_secretsmanager_secret.secrets : s.name => s.arn }
}

output "secret_names" {
  description = "Mapping of secret names to themselves"
  value       = { for s in aws_secretsmanager_secret.secrets : s.name => s.name }
}

output "kms_key_arns" {
  description = "Mapping of KMS key names to ARNs"
  value       = { for key, kms in aws_kms_key.kms : key => kms.arn }
}
