locals {
  create_repo_secret = var.gitops_repo_url != "" && var.gitops_repo_token != ""
  create_root_app    = var.create_root_app && var.gitops_repo_url != ""
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Argo CD
# -----------------------------------------------------------------------------
resource "helm_release" "argocd" {
  name       = var.release_name
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = concat([
    yamlencode({
      configs = {
        params = {
          # TLS is terminated at the ingress/load balancer, not by argocd-server.
          "server.insecure" = true
        }
      }
      server = {
        service = {
          type = var.server_service_type
        }
      }
    })
  ], var.extra_values)
}

# -----------------------------------------------------------------------------
# GitOps repository credentials (GitHub token)
# -----------------------------------------------------------------------------
resource "kubernetes_secret_v1" "gitops_repo" {
  count = local.create_repo_secret ? 1 : 0

  metadata {
    name      = "gitops-repo"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name

    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.gitops_repo_url
    username = var.gitops_repo_username
    password = var.gitops_repo_token
  }

  depends_on = [helm_release.argocd]
}

# -----------------------------------------------------------------------------
# Root application (app-of-apps)
# -----------------------------------------------------------------------------
# Created through the argocd-apps chart so the Application CRD doesn't have to
# exist at plan time (kubernetes_manifest would need it).
resource "helm_release" "root_app" {
  count      = local.create_root_app ? 1 : 0
  name       = "${var.release_name}-root-app"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version

  values = [
    yamlencode({
      applications = {
        (var.root_app_name) = {
          namespace  = var.namespace
          project    = "default"
          finalizers = ["resources-finalizer.argocd.argoproj.io"]

          source = {
            repoURL        = var.gitops_repo_url
            targetRevision = var.root_app_revision
            path           = var.root_app_path
            directory = {
              recurse = true
            }
          }

          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = var.namespace
          }

          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
            syncOptions = ["CreateNamespace=true"]
          }
        }
      }
    })
  ]

  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.gitops_repo,
  ]
}
