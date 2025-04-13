output "ecr_repo_name" {
  description = "ecr_repo_name"
  value = aws_ecr_repository.ecr_repo.name
}

output "ecr_repo_uri" {
  description = "ecr_repo_uri"
  value = aws_ecr_repository.ecr_repo.repository_url
}
