# -----------------------------------------------------------------------------
# IAM policy
# -----------------------------------------------------------------------------
# iam_policy.json is the upstream policy for the controller release that matches
# var.chart_version:
# https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.3/docs/install/iam_policy.json
# The role itself is an IRSA role from modules/iam (irsa_roles).
resource "aws_iam_policy" "this" {
  name        = "${var.name_prefix}-aws-load-balancer-controller"
  description = "Permissions for the AWS Load Balancer Controller on ${var.cluster_name}."
  policy      = file("${path.module}/iam_policy.json")

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Controller
# -----------------------------------------------------------------------------
resource "helm_release" "this" {
  name       = var.release_name
  namespace  = var.namespace
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600

  values = concat([
    yamlencode({
      clusterName  = var.cluster_name
      region       = var.aws_region
      vpcId        = var.vpc_id
      replicaCount = var.replica_count

      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = var.irsa_role_arn
        }
      }
    })
  ], var.extra_values)
}
