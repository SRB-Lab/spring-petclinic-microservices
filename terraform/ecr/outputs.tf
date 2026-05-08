# ─────────────────────────────────────────────────────────────────────────────
# Outputs — share these with the rest of the team after `terraform apply`
# ─────────────────────────────────────────────────────────────────────────────

output "ecr_registry_url" {
  description = "ECR registry base URL (account-id.dkr.ecr.region.amazonaws.com)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "repository_urls" {
  description = "Full push/pull URL for each microservice repository"
  value = {
    for name, repo in aws_ecr_repository.services :
    name => repo.repository_url
  }
}

output "ecr_pull_policy_arn" {
  description = "ARN of the ECR pull IAM policy — give this to Infrastructure Engineer-3 to attach to EKS node role"
  value       = aws_iam_policy.ecr_pull.arn
}

output "ecr_push_policy_arn" {
  description = "ARN of the ECR push IAM policy — attach to the CI/CD pipeline IAM user"
  value       = aws_iam_policy.ecr_push.arn
}
