output "namespace" {
  description = "Namespace the monitoring stack runs in."
  value       = kubernetes_namespace_v1.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name of kube-prometheus-stack."
  value       = helm_release.kube_prometheus_stack.name
}

output "chart_version" {
  description = "Installed kube-prometheus-stack chart version."
  value       = helm_release.kube_prometheus_stack.version
}

output "storage_class_name" {
  description = "StorageClass used for monitoring volumes."
  value       = var.storage_class_name
}

output "grafana_admin_password" {
  description = "Grafana admin password."
  value       = local.grafana_admin_password
  sensitive   = true
}

output "grafana_port_forward_command" {
  description = "Command to reach Grafana locally on http://localhost:3000."
  value       = "kubectl -n ${var.namespace} port-forward svc/${var.release_name}-grafana 3000:80"
}
