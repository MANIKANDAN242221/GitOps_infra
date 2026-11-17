aws_region   = "ap-south-1"
project_name = "gitops"
environment  = "dev"

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
vpc_cidr = "10.10.0.0/16"
az_count = 2

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
kubernetes_version     = "1.34"
endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"]

terraform_ci_role_arn = "arn:aws:iam::772721871682:role/gitops-terraform-ci-role" # CHANGE ME: bootstrap output
cluster_admin_arns    = []                                                        # e.g. your SSO admin role ARN

node_instance_types = ["c7i-flex.large"]
node_capacity_type  = "ON_DEMAND"
node_min_size       = 1
node_desired_size   = 2
node_max_size       = 3

# -----------------------------------------------------------------------------
# ECR + GitHub Actions
# -----------------------------------------------------------------------------
ecr_repository_names = ["frontend", "backend"]
ecr_force_delete     = true

github_app_repositories = ["MANIKANDAN242221/GitOps_app"]

# -----------------------------------------------------------------------------
# Argo CD (token comes from TF_VAR_gitops_repo_token)
# -----------------------------------------------------------------------------
gitops_repo_url      = "https://github.com/MANIKANDAN242221/GitOps_Argocd.git" # CHANGE ME
gitops_repo_username = "GitOps_token"
gitops_repo_path     = "apps/dev"
gitops_repo_revision = "main"

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
prometheus_retention    = "7d"
prometheus_storage_size = "20Gi"
