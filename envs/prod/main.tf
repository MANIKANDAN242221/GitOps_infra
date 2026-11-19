locals {
  name         = "${var.project_name}-${var.environment}"
  cluster_name = local.name

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # /16 VPC: large /20 private subnets (pods take VPC IPs with vpc-cni), small /24 public ones.
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 240 + i)]

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  public_subnets     = local.public_subnets
  private_subnets    = local.private_subnets
  enable_nat_gateway = true
  cluster_name       = local.cluster_name
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  node_subnet_ids = module.vpc.private_subnet_ids

  endpoint_public_access    = var.endpoint_public_access
  public_access_cidrs       = var.public_access_cidrs
  cluster_api_allowed_cidrs = [module.vpc.vpc_cidr]

  # Admins are listed explicitly so laptop and CI applies both keep access.
  bootstrap_cluster_creator_admin_permissions = false
  cluster_admin_arns                          = distinct(concat([var.terraform_ci_role_arn], var.cluster_admin_arns))

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_labels = {
    environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  repository_names  = var.ecr_repository_names
  repository_prefix = var.environment
  force_delete      = var.ecr_force_delete
}

# -----------------------------------------------------------------------------
# IAM (GitHub Actions image push role + IRSA roles)
# -----------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name

  enable_github_actions_role  = length(var.github_app_repositories) > 0
  create_github_oidc_provider = false # owned by bootstrap/
  github_repositories         = var.github_app_repositories
  ecr_repository_arns         = values(module.ecr.repository_arns)

  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_issuer       = module.eks.oidc_issuer
  irsa_roles = {
    aws-load-balancer-controller = {
      namespace       = "kube-system"
      service_account = "aws-load-balancer-controller"
      policy_arns     = [module.aws_load_balancer_controller.iam_policy_arn]
    }
  }
}

# -----------------------------------------------------------------------------
# AWS Load Balancer Controller (turns Ingress/Service into ALB/NLB)
# -----------------------------------------------------------------------------
module "aws_load_balancer_controller" {
  source = "../../modules/aws-load-balancer-controller"

  name_prefix   = local.name
  cluster_name  = module.eks.cluster_name
  vpc_id        = module.vpc.vpc_id
  aws_region    = var.aws_region
  irsa_role_arn = module.iam.irsa_role_arns["aws-load-balancer-controller"]

  # Nodes, add-ons and access entries must exist before Helm can talk to the cluster.
  depends_on = [module.eks]
}

# -----------------------------------------------------------------------------
# Argo CD
# -----------------------------------------------------------------------------
module "argocd" {
  source = "../../modules/argocd-bootstrap"

  gitops_repo_url      = var.gitops_repo_url
  gitops_repo_username = var.gitops_repo_username
  gitops_repo_token    = var.gitops_repo_token
  root_app_name        = "root-${var.environment}"
  root_app_path        = var.gitops_repo_path
  root_app_revision    = var.gitops_repo_revision

  # Ingresses synced by Argo CD need the controller (and its webhook) running first;
  # on destroy, Argo CD goes first so the controller can still clean up its ALBs.
  depends_on = [module.eks, module.aws_load_balancer_controller]
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring-bootstrap"

  prometheus_retention    = var.prometheus_retention
  prometheus_storage_size = var.prometheus_storage_size
  grafana_admin_password  = var.grafana_admin_password

  # Needs the EBS CSI driver add-on for its volumes.
  depends_on = [module.eks]
}
