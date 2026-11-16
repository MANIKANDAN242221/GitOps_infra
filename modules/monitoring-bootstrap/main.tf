locals {
  grafana_admin_password = var.grafana_admin_password == "" ? random_password.grafana[0].result : var.grafana_admin_password
}

# -----------------------------------------------------------------------------
# gp3 StorageClass (EBS CSI driver)
# -----------------------------------------------------------------------------
resource "kubernetes_storage_class_v1" "gp3" {
  count = var.create_gp3_storage_class ? 1 : 0

  metadata {
    name = var.storage_class_name

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = tostring(var.gp3_default_storage_class)
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Grafana admin credentials
# -----------------------------------------------------------------------------
resource "random_password" "grafana" {
  count   = var.grafana_admin_password == "" ? 1 : 0
  length  = 24
  special = false
}

resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    admin-user     = "admin"
    admin-password = local.grafana_admin_password
  }
}

# -----------------------------------------------------------------------------
# kube-prometheus-stack (Prometheus, Alertmanager, Grafana, exporters)
# -----------------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  name       = var.release_name
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 900

  values = concat([
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention

          # Pick up ServiceMonitors/PodMonitors from every namespace, not just this release.
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
          ruleSelectorNilUsesHelmValues           = false

          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class_name
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }
        }
      }

      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class_name
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.alertmanager_storage_size
                  }
                }
              }
            }
          }
        }
      }

      grafana = {
        admin = {
          existingSecret = kubernetes_secret_v1.grafana_admin.metadata[0].name
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }
        service = {
          type = var.grafana_service_type
        }
        persistence = {
          enabled          = true
          storageClassName = var.storage_class_name
          size             = var.grafana_storage_size
        }
      }

      # Control plane components are managed by EKS and not scrapeable.
      kubeControllerManager = { enabled = false }
      kubeScheduler         = { enabled = false }
      kubeEtcd              = { enabled = false }
      kubeProxy             = { enabled = false }
    })
  ], var.extra_values)

  depends_on = [kubernetes_storage_class_v1.gp3]
}
