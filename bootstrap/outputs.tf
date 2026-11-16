output "state_bucket_name" {
  description = "S3 bucket holding Terraform state; set it as TF_STATE_BUCKET in GitHub Actions variables."
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_region" {
  description = "Region of the state bucket."
  value       = var.aws_region
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "terraform_ci_role_arn" {
  description = "ARN of the Terraform CI role; set it as TF_ROLE_ARN in GitHub Actions variables."
  value       = aws_iam_role.terraform_ci.arn
}

output "backend_config" {
  description = "Flags for terraform init in envs/<env>."
  value       = "-backend-config=\"bucket=${aws_s3_bucket.state.bucket}\" -backend-config=\"region=${var.aws_region}\""
}
