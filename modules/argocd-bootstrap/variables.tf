variable "namespace" {
  description = "Namespace Argo CD is installed into."
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for Argo CD."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the argo-cd Helm chart."
  type        = string
  default     = "10.17.2"
}

variable "server_service_type" {
  description = "Service type for argocd-server (ClusterIP, LoadBalancer or NodePort)."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "LoadBalancer", "NodePort"], var.server_service_type)
    error_message = "server_service_type must be ClusterIP, LoadBalancer or NodePort."
  }
}

variable "extra_values" {
  description = "Extra YAML values passed to the argo-cd chart (applied after the module's defaults)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# GitOps repository (GitHub)
# -----------------------------------------------------------------------------
variable "gitops_repo_url" {
  description = "HTTPS URL of the GitHub repo Argo CD syncs from. Leave empty to skip the repo secret and root app."
  type        = string
  default     = ""
}

variable "gitops_repo_username" {
  description = "Username for the GitOps repo. With a GitHub token any non-empty value works, e.g. x-access-token."
  type        = string
  default     = ""
}

variable "gitops_repo_token" {
  description = "Read-only GitHub fine-grained token (Contents: read) or GitHub App token for the GitOps repo. Leave empty for a public repo."
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Root application (app-of-apps)
# -----------------------------------------------------------------------------
variable "create_root_app" {
  description = "Create a root Application that syncs everything under root_app_path."
  type        = bool
  default     = true
}

variable "root_app_name" {
  description = "Name of the root Application."
  type        = string
  default     = "root"
}

variable "root_app_path" {
  description = "Path in the GitOps repo holding the child Applications, e.g. apps/dev."
  type        = string
  default     = "apps"
}

variable "root_app_revision" {
  description = "Git branch, tag or commit the root Application tracks."
  type        = string
  default     = "main"
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart used to create the root Application."
  type        = string
  default     = "2.0.8"
}
