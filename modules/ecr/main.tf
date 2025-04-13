resource "aws_ecr_repository" "ecr_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = var.ecr_repo_image_tag_mutability
  force_delete         = true # Only here considering testing env

  image_scanning_configuration {
    scan_on_push = var.ecr_repo_scan_on_push
  }
}
