variable "ecr_repo_name" {
  description = "ecr_repo_name"
  type = string
}

variable "ecr_repo_image_tag_mutability" {
  description = "ecr_repo_image_tag_mutability"
  type = string
}

variable "ecr_repo_scan_on_push" {
  description = "ecr_repo_scan_on_push"
  type = bool
}
