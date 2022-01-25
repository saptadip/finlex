resource "aws_ecr_repository" "app_ecr_repo" {
  name = var.ecr_repo_name
}

