output "iam_role_arn" {
  description = "ARN of IAM role"
  value       = aws_iam_role.iam_role[0].arn
}

output "iam_role_name" {
  description = "Name of IAM role"
  value       = aws_iam_role.iam_role[0].name
}

output "iam_role_path" {
  description = "Path of IAM role"
  value       = aws_iam_role.iam_role[0].path
}

output "iam_role_unique_id" {
  description = "Unique ID of IAM role"
  value       = aws_iam_role.iam_role[0].unique_id
}