variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod, ...)."
  type        = string
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC (a /16 is expected by the subnet maths in main.tf)."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
variable "kubernetes_version" {
  description = "Kubernetes version for the cluster."
  type        = string
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "terraform_ci_role_arn" {
  description = "Terraform CI role from bootstrap/ (terraform_ci_role_arn output); gets cluster admin."
  type        = string
}

variable "cluster_admin_arns" {
  description = "Other IAM role/user ARNs that get cluster admin (e.g. your SSO admin role)."
  type        = list(string)
  default     = []
}

variable "node_instance_types" {
  description = "EC2 instance types for the node group."
  type        = list(string)
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT."
  type        = string
  default     = "ON_DEMAND"
}

variable "node_min_size" {
  description = "Minimum number of nodes."
  type        = number
}

variable "node_desired_size" {
  description = "Desired number of nodes on create."
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of nodes."
  type        = number
}

# -----------------------------------------------------------------------------
# ECR + GitHub Actions
# -----------------------------------------------------------------------------
variable "ecr_repository_names" {
  description = "One ECR repository per service image."
  type        = list(string)
}

variable "ecr_force_delete" {
  description = "Allow destroying repositories that still hold images."
  type        = bool
  default     = false
}

variable "github_app_repositories" {
  description = "GitHub app repositories (owner/repo) whose workflows may push images to ECR."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Argo CD
# -----------------------------------------------------------------------------
variable "gitops_repo_url" {
  description = "HTTPS URL of the GitHub GitOps repo Argo CD syncs from."
  type        = string
  default     = ""
}

variable "gitops_repo_username" {
  description = "Username for the GitOps repo. With a GitHub token any non-empty value works, e.g. x-access-token."
  type        = string
  default     = ""
}

variable "gitops_repo_token" {
  description = "GitHub fine-grained token with Contents: read on the GitOps repo. Pass via TF_VAR_gitops_repo_token, never in tfvars."
  type        = string
  default     = ""
  sensitive   = true
}

variable "gitops_repo_path" {
  description = "Path in the GitOps repo holding this environment's Applications."
  type        = string
}

variable "gitops_repo_revision" {
  description = "Branch, tag or commit Argo CD tracks."
  type        = string
  default     = "main"
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
variable "prometheus_retention" {
  description = "How long Prometheus keeps metrics."
  type        = string
  default     = "7d"
}

variable "prometheus_storage_size" {
  description = "Size of the Prometheus volume."
  type        = string
  default     = "20Gi"
}

variable "grafana_admin_password" {
  description = "Grafana admin password. Leave empty to generate one. Pass via TF_VAR_grafana_admin_password."
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Public UIs (Argo CD, Grafana, Prometheus)
# -----------------------------------------------------------------------------
variable "expose_uis" {
  description = "Give Argo CD, Grafana and Prometheus internet-facing NLBs. Prometheus has no login, so keep ui_allowed_cidrs tight."
  type        = bool
  default     = false
}

variable "ui_allowed_cidrs" {
  description = "Source CIDRs allowed to reach the UI load balancers."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
