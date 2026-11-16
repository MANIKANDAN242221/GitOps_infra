variable "namespace" {
  description = "Namespace the monitoring stack is installed into."
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Helm release name for kube-prometheus-stack."
  type        = string
  default     = "kube-prometheus-stack"
}

variable "chart_version" {
  description = "Version of the kube-prometheus-stack Helm chart."
  type        = string
  default     = "93.2.0"
}

variable "extra_values" {
  description = "Extra YAML values passed to the chart (applied after the module's defaults)."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
variable "create_gp3_storage_class" {
  description = "Create a gp3 StorageClass backed by the EBS CSI driver."
  type        = bool
  default     = true
}

variable "gp3_default_storage_class" {
  description = "Mark the gp3 StorageClass as the cluster default."
  type        = bool
  default     = true
}

variable "storage_class_name" {
  description = "StorageClass used for Prometheus, Alertmanager and Grafana volumes."
  type        = string
  default     = "gp3"
}

# -----------------------------------------------------------------------------
# Prometheus
# -----------------------------------------------------------------------------
variable "prometheus_retention" {
  description = "How long Prometheus keeps metrics, e.g. 7d or 30d."
  type        = string
  default     = "7d"
}

variable "prometheus_storage_size" {
  description = "Size of the Prometheus volume."
  type        = string
  default     = "20Gi"
}

variable "alertmanager_storage_size" {
  description = "Size of the Alertmanager volume."
  type        = string
  default     = "2Gi"
}

# -----------------------------------------------------------------------------
# Grafana
# -----------------------------------------------------------------------------
variable "grafana_admin_password" {
  description = "Grafana admin password. Leave empty to generate one."
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "Size of the Grafana volume."
  type        = string
  default     = "5Gi"
}

variable "grafana_service_type" {
  description = "Service type for Grafana (ClusterIP, LoadBalancer or NodePort)."
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "LoadBalancer", "NodePort"], var.grafana_service_type)
    error_message = "grafana_service_type must be ClusterIP, LoadBalancer or NodePort."
  }
}
