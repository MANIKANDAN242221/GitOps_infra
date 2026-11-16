variable "name_prefix" {
  description = "Prefix for all IAM resource names, e.g. the cluster or environment name."
  type        = string
}

# -----------------------------------------------------------------------------
# GitHub Actions
# -----------------------------------------------------------------------------
variable "enable_github_actions_role" {
  description = "Create an IAM role GitHub Actions workflows can assume via OIDC to push images."
  type        = bool
  default     = true
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider. Leave false when bootstrap/ already created it."
  type        = bool
  default     = false
}

variable "github_repositories" {
  description = "GitHub repositories (owner/repo) allowed to assume the CI role."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for r in var.github_repositories : can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", r))])
    error_message = "github_repositories entries must look like owner/repo."
  }
}

variable "github_subjects" {
  description = "Explicit OIDC subject patterns, e.g. repo:owner/app:ref:refs/heads/main. Overrides github_repositories."
  type        = list(string)
  default     = []
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs the CI role may push to."
  type        = list(string)
  default     = []
}

variable "eks_cluster_arns" {
  description = "EKS cluster ARNs the CI role may describe (only needed if CI talks to the cluster)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# IRSA
# -----------------------------------------------------------------------------
variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS cluster's OIDC provider (module.eks.oidc_provider_arn)."
  type        = string
  default     = ""
}

variable "eks_oidc_issuer" {
  description = "EKS OIDC issuer without https:// (module.eks.oidc_issuer)."
  type        = string
  default     = ""
}

variable "irsa_roles" {
  description = "IRSA roles keyed by short name. Each maps one service account to managed and/or inline policies."
  type = map(object({
    namespace       = string
    service_account = string
    policy_arns     = optional(list(string), [])
    inline_policy   = optional(string)
  }))
  default = {}

  validation {
    condition     = length(var.irsa_roles) == 0 || (var.eks_oidc_provider_arn != "" && var.eks_oidc_issuer != "")
    error_message = "eks_oidc_provider_arn and eks_oidc_issuer are required when irsa_roles is set."
  }
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
