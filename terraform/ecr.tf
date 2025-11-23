# --- AWS ECR (Elastic Container Registry) ---
# This repository stores the Docker images for the FinTech API.

resource "aws_ecr_repository" "fintech_app_repo" {
  name                 = "fintech-api-repo"
  image_tag_mutability = "MUTABLE"

  # SECURITY BEST PRACTICE:
  # Automatically scan images for vulnerabilities (CVEs) upon push.
  image_scanning_configuration {
    scan_on_push = true
  }

  # Allow Terraform to destroy the repo even if it contains images (Clean-up)
  force_delete = true
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository to push Docker images to."
  value       = aws_ecr_repository.fintech_app_repo.repository_url
}