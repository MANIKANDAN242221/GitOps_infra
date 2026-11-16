output "namespace" {
  description = "Namespace Argo CD runs in."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "release_name" {
  description = "Helm release name of Argo CD."
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "Installed argo-cd chart version."
  value       = helm_release.argocd.version
}

output "root_app_name" {
  description = "Name of the root Application (null when not created)."
  value       = local.create_root_app ? var.root_app_name : null
}

output "initial_admin_password_command" {
  description = "Command to read the initial admin password."
  value       = "kubectl -n ${var.namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}
