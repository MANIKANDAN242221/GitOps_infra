aws_region   = "us-east-1"
project_name = "gitops"
environment  = "prod"

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
vpc_cidr = "10.20.0.0/16"
az_count = 3

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
kubernetes_version     = "1.34"
endpoint_public_access = true
public_access_cidrs    = ["0.0.0.0/0"] # CHANGE ME: restrict to office/VPN CIDRs

terraform_ci_role_arn = "arn:aws:iam::111122223333:role/gitops-terraform-ci-role" # CHANGE ME: bootstrap output
cluster_admin_arns    = []                                                        # e.g. your SSO admin role ARN

node_instance_types = ["m6i.large"]
node_capacity_type  = "ON_DEMAND"
node_min_size       = 2
node_desired_size   = 3
node_max_size       = 6

# -----------------------------------------------------------------------------
# ECR + GitHub Actions
# -----------------------------------------------------------------------------
ecr_repository_names = ["frontend", "backend"]
ecr_force_delete     = false

github_app_repositories = ["my-org/my-app"] # CHANGE ME

# -----------------------------------------------------------------------------
# Argo CD (token comes from TF_VAR_gitops_repo_token)
# -----------------------------------------------------------------------------
gitops_repo_url      = "https://github.com/my-org/gitops-manifests.git" # CHANGE ME
gitops_repo_username = "x-access-token"                                 # any non-empty value for a GitHub token
gitops_repo_path     = "apps/prod"
gitops_repo_revision = "main"

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
prometheus_retention    = "30d"
prometheus_storage_size = "100Gi"
