# infra-terraform

AWS infrastructure for the GitOps platform: VPC, EKS, ECR and IAM, plus Argo CD and the monitoring stack installed on the cluster. GitHub Actions runs plan and apply using OIDC, so no AWS keys are stored.

## Layout

```
bootstrap/                 one-time per account: state bucket, GitHub OIDC provider, Terraform CI role
envs/dev, envs/prod        one root module per environment (same code, different tfvars)
modules/
  vpc/                     VPC, public/private subnets, single NAT gateway
  eks/                     EKS cluster, managed node group, OIDC (IRSA), core add-ons + EBS CSI
  ecr/                     image repositories with scanning and lifecycle policies
  iam/                     GitHub Actions image-push role, IRSA roles
  argocd-bootstrap/        Argo CD (Helm), GitHub repo credentials, root app-of-apps
  monitoring-bootstrap/    kube-prometheus-stack (Prometheus, Alertmanager, Grafana), gp3 StorageClass
.github/workflows/         fmt/validate/plan on PRs, approved apply on main (dev, then prod)
```

## Prerequisites

- Terraform >= 1.10 (S3 lock files), AWS CLI v2, kubectl
- Admin AWS credentials for the first `bootstrap` run

## 1. Bootstrap (once per AWS account)

```sh
make bootstrap GITHUB_REPO=my-org/infra-terraform AWS_REGION=us-east-1
```

Then, in the infra repo on GitHub, go to **Settings → Secrets and variables → Actions**:

| Name | Kind | Value |
|---|---|---|
| `TF_ROLE_ARN` | variable | bootstrap `terraform_ci_role_arn` |
| `TF_STATE_BUCKET` | variable | bootstrap `state_bucket_name` |
| `AWS_REGION` | variable | e.g. `us-east-1` |
| `GITOPS_REPO_TOKEN` | secret | fine-grained token with **Contents: read** on the GitOps repo |
| `GRAFANA_ADMIN_PASSWORD` | secret | optional; generated if unset |

Under **Settings → Environments**, create `dev` and `prod` and add **required reviewers** to each.
That is the manual approval before each apply. On a private repo, required reviewers need GitHub Enterprise;
without them the applies run straight after the plans.

## 2. Configure environments

Edit `envs/<env>/terraform.tfvars` and replace every `CHANGE ME`:

- `terraform_ci_role_arn`: bootstrap output
- `cluster_admin_arns`: your own admin/SSO role, so you can use kubectl too
- `github_app_repositories`: app repos (`owner/repo`) whose workflows push images
- `gitops_repo_url` / `gitops_repo_username`: the GitOps manifests repo; any non-empty username works with a GitHub token

Commit the provider lock files (`bootstrap/` and `envs/*/.terraform.lock.hcl`). They cover Linux, Windows and macOS.
After bumping a provider, regenerate them with:

```sh
terraform -chdir=envs/dev providers lock -platform=linux_amd64 -platform=windows_amd64 -platform=darwin_arm64
```

## 3. Deploy

Push to a branch and open a PR. The workflow runs `fmt`, `validate` and `plan` for both environments
(each plan's summary appears on the run page). After the merge, `main` runs the plans again, then waits
for a reviewer to approve **apply-dev**, then **apply-prod**.

From a laptop:

```sh
make plan  ENV=dev TF_STATE_BUCKET=<bucket>
make apply ENV=dev
make kubeconfig ENV=dev TF_STATE_BUCKET=<bucket>
```

## After apply

```sh
terraform -chdir=envs/dev output                       # endpoints, ECR URLs, CI role ARN
terraform -chdir=envs/dev output -raw grafana_admin_password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

In each **app** repo's workflow, grant `id-token: write` and assume `github_actions_role_arn` with
`aws-actions/configure-aws-credentials` the same way `.github/workflows/terraform.yml` does here,
then push to the URLs in `ecr_repository_urls`.
Argo CD syncs `gitops_repo_path` from the GitOps repo.
