variable "aws_region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names."
  type        = string
  default     = "gitops"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state. Defaults to <project>-tfstate-<account id>."
  type        = string
  default     = ""
}

variable "noncurrent_state_retention_days" {
  description = "Days to keep old state versions before they are deleted."
  type        = number
  default     = 90
}

# -----------------------------------------------------------------------------
# GitHub Actions
# -----------------------------------------------------------------------------
variable "github_infra_repo" {
  description = "GitHub repository (owner/repo) of this Terraform code; its workflows get the Terraform role."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_infra_repo))
    error_message = "github_infra_repo must look like owner/repo."
  }
}

variable "terraform_ci_subjects" {
  description = "OIDC subject patterns allowed to assume the Terraform role, e.g. repo:owner/repo:environment:prod. Defaults to anything in github_infra_repo."
  type        = list(string)
  default     = []
}

variable "terraform_ci_policy_arns" {
  description = "Managed policies attached to the Terraform CI role."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "tags" {
  description = "Extra tags applied to all resources."
  type        = map(string)
  default     = {}
}
