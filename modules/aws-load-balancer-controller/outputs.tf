output "iam_policy_arn" {
  description = "ARN of the controller's IAM policy, for the IRSA role."
  value       = aws_iam_policy.this.arn
}

output "release_name" {
  description = "Helm release name of the controller."
  value       = helm_release.this.name
}

output "namespace" {
  description = "Namespace the controller runs in."
  value       = helm_release.this.namespace
}
