output "repository_urls" {
  description = "Map of repository name to repository URL."
  value       = { for k, r in aws_ecr_repository.main : k => r.repository_url }
}

output "repository_arns" {
  description = "Map of repository name to repository ARN."
  value       = { for k, r in aws_ecr_repository.main : k => r.arn }
}

output "repository_names" {
  description = "Map of input name to full repository name (including prefix)."
  value       = { for k, r in aws_ecr_repository.main : k => r.name }
}

output "registry_id" {
  description = "Registry (AWS account) ID the repositories live in."
  value       = try(values(aws_ecr_repository.main)[0].registry_id, null)
}
