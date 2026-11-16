# bootstrap

One-time setup per AWS account. Run it from a laptop with admin credentials **before** any environment.

It creates:

| Resource | Purpose |
|---|---|
| S3 bucket | Remote state for `envs/*` (versioned, encrypted, TLS-only, S3 lock files) |
| GitHub Actions OIDC provider | Lets GitHub Actions jobs get short-lived AWS credentials, no access keys |
| Terraform CI role | Assumed by this repo's pipelines to plan/apply `envs/*` |

## Run

```sh
cd bootstrap
terraform init
terraform apply -var="github_infra_repo=my-org/infra-terraform"
```

Then copy the outputs into **GitHub → Settings → Secrets and variables → Actions → Variables**:

| Variable | Value |
|---|---|
| `TF_STATE_BUCKET` | `state_bucket_name` output |
| `TF_ROLE_ARN` | `terraform_ci_role_arn` output |
| `AWS_REGION` | the region you used |

## State

This stack keeps its state in a local `terraform.tfstate` (it creates the bucket, so it can't live in it at first).
Don't lose that file. Optionally move it into the bucket afterwards: add a `backend "s3"` block with
`key = "bootstrap/terraform.tfstate"` and run `terraform init -migrate-state`.

## Security note

By default any branch, PR or environment of the infra repo can assume the Terraform role, so PR workflows can run `plan`.
Since the role has `AdministratorAccess`, restrict who can push to the repo. To allow only `main` and the two deployment environments, set:

```hcl
terraform_ci_subjects = [
  "repo:my-org/infra-terraform:ref:refs/heads/main",
  "repo:my-org/infra-terraform:environment:dev",
  "repo:my-org/infra-terraform:environment:prod",
]
```
