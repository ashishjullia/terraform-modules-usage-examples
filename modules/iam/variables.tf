variable "create_role" {
  description = "Whether to create a role"
  type        = bool
  default     = false
}

variable "role_name" {
  description = "IAM role name"
  type        = string
  default     = null 
}

variable "role_assume_role_policy_data" {
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

variable "custom_role_policy_arns" {
  description = "List of ARNs of IAM policies to attach to IAM role"
  type        = list(string)
  default     = []
}

variable "number_of_custom_role_policy_arns" {
  description = "Number of IAM policies to attach to IAM role"
  type        = number
  default     = null
}

variable "create_iam_role_inline_policy" {
  description = "Whether to create iam role inline policy or not"
  type        = bool
}

variable "inline_policy_statements" {
  description = "List of inline policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) to attach to IAM role as an inline policy"
  type        = any
  default     = []
}
