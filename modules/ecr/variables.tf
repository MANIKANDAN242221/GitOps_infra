variable "repository_names" {
  description = "Names of the ECR repositories to create (one per service image)."
  type        = list(string)

  validation {
    condition     = length(var.repository_names) > 0
    error_message = "At least one repository name is required."
  }

  validation {
    condition     = alltrue([for n in var.repository_names : can(regex("^[a-z0-9]+(?:[._-][a-z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-z0-9]+)*)*$", n))])
    error_message = "Repository names must be lowercase and may contain only letters, digits, '.', '_', '-' and '/'."
  }
}

variable "repository_prefix" {
  description = "Optional namespace prepended to each repository name, e.g. \"dev\" gives dev/<name>."
  type        = string
  default     = ""
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE. IMMUTABLE stops tags being overwritten (recommended for GitOps)."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities when they are pushed."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for repository encryption. Leave empty to use AES256."
  type        = string
  default     = ""
}

variable "force_delete" {
  description = "Allow Terraform to delete repositories that still contain images."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Lifecycle policy
# -----------------------------------------------------------------------------
variable "enable_lifecycle_policy" {
  description = "Attach a lifecycle policy that cleans up old images."
  type        = bool
  default     = true
}

variable "untagged_image_expiry_days" {
  description = "Days after which untagged images are expired."
  type        = number
  default     = 7

  validation {
    condition     = var.untagged_image_expiry_days >= 1
    error_message = "untagged_image_expiry_days must be at least 1."
  }
}

variable "max_image_count" {
  description = "Maximum number of images kept per repository."
  type        = number
  default     = 30

  validation {
    condition     = var.max_image_count >= 1
    error_message = "max_image_count must be at least 1."
  }
}

# -----------------------------------------------------------------------------
# Access
# -----------------------------------------------------------------------------
variable "pull_principal_arns" {
  description = "Extra IAM principals (e.g. other accounts) allowed to pull. Same-account nodes don't need this."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
