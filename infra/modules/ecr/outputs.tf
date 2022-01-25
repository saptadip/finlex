output "ecr_repo_url" {
  value = aws_ecr_repository.app_ecr_repo.repository_url
}

output "ecr_repo_arn" {
  value = aws_ecr_repository.app_ecr_repo.arn
}
