output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider (null when the CI role is disabled)."
  value       = var.enable_github_actions_role ? local.github_oidc_provider_arn : null
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role; set it as the AWS_ROLE_ARN variable in the app repo (null when disabled)."
  value       = try(aws_iam_role.github_actions[0].arn, null)
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions role (null when disabled)."
  value       = try(aws_iam_role.github_actions[0].name, null)
}

output "irsa_role_arns" {
  description = "Map of IRSA role key to role ARN, for the eks.amazonaws.com/role-arn annotation."
  value       = { for k, r in aws_iam_role.irsa : k => r.arn }
}
