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
