resource "aws_secretsmanager_secret" "secrets" {
  for_each = var.secrets_metadata

  name       = each.value.secret_name
  kms_key_id = aws_kms_key.kms[each.value.kms_key].id
}

resource "aws_secretsmanager_secret_version" "secrets_version" {
  for_each      = aws_secretsmanager_secret.secrets
  secret_id     = each.value.id
  secret_string = jsonencode(var.secrets_values[each.key])
}

resource "aws_kms_key" "kms" {
  for_each                = var.secretsmanager_kms_keys
  description             = each.value.description
  deletion_window_in_days = each.value.deletion_window_in_days
}
