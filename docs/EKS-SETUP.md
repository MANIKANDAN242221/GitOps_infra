# EKS Setup – dev (gitops-dev, ap-south-1)

This repo creates everything below with Terraform through the `terraform-dev` GitHub Actions workflow.
Each step shows **what gets created**, **where it is in Terraform**, and **how to do the same in the AWS Console**
(for learning or troubleshooting only. Don't create these by hand, or Terraform and AWS will drift apart).

| Setting | Value |
|---|---|
| Account | 772721871682 |
| Region | ap-south-1 (Mumbai) |
| Cluster name | gitops-dev |
| VPC CIDR | 10.10.0.0/16 |

---

## STEP-0  One-time bootstrap (laptop)

Creates the Terraform state bucket, the GitHub OIDC provider and the CI role `gitops-terraform-ci-role`.

```sh
cd bootstrap
terraform init
terraform apply
```

Then in GitHub → `GitOps_infra` → Settings → Secrets and variables → Actions:

| Type | Name | Value |
|---|---|---|
| Variable | `TF_ROLE_ARN` | `arn:aws:iam::772721871682:role/gitops-terraform-ci-role` |
| Variable | `AWS_REGION` | `ap-south-1` |
| Secret | `GITOPS_REPO_TOKEN` | GitHub token that can read `GitOps_Argocd` |
| Secret | `GRAFANA_ADMIN_PASSWORD` | any strong password |

> If the workflow keeps printing `Assuming role with OIDC`, the role's trust policy must allow both
> `repo:MANIKANDAN242221/GitOps_infra:*` and `repo:MANIKANDAN242221@*/GitOps_infra@*:*`.

---

## STEP-1  Create the VPC

Terraform: `modules/vpc`

| Resource | Value |
|---|---|
| VPC | `gitops-dev`, 10.10.0.0/16, DNS hostnames on |
| Public subnets | `10.10.240.0/24` (ap-south-1a), `10.10.241.0/24` (ap-south-1b) |
| Private subnets | `10.10.0.0/20` (ap-south-1a), `10.10.16.0/20` (ap-south-1b) |
| Internet Gateway | `gitops-dev-igw` |
| NAT Gateway | `gitops-dev-nat-gateway` (in a public subnet, with Elastic IP) |
| Public route table | `0.0.0.0/0` → Internet Gateway |
| Private route table | `0.0.0.0/0` → NAT Gateway |

Console: VPC → Create VPC → **VPC and more** → 2 AZs, 2 public + 2 private subnets, 1 NAT gateway.

---

## STEP-2  Tag the subnets for EKS

Terraform: `modules/vpc` (added automatically)

| Subnet | Key | Value |
|---|---|---|
| Public (both) | `kubernetes.io/role/elb` | `1` |
| Private (both) | `kubernetes.io/role/internal-elb` | `1` |
| All 4 subnets | `kubernetes.io/cluster/gitops-dev` | `shared` |

Console: VPC → Subnets → select subnet → Actions → Manage tags → Add tag.

> `elb` = internet-facing load balancers go in public subnets.
> `internal-elb` = internal load balancers go in private subnets.

---

## STEP-3  Create the EKS cluster

Terraform: `modules/eks` (`aws_eks_cluster.main`)

| Setting | Value |
|---|---|
| Name | `gitops-dev` |
| Kubernetes version | 1.34 |
| Cluster role | `gitops-dev-cluster-role` (AmazonEKSClusterPolicy, AmazonEKSVPCResourceController) |
| Subnets | all 4 subnets |
| Endpoint | public + private |
| Authentication mode | EKS API and ConfigMap (access entries) |
| Add-ons | `vpc-cni`, `kube-proxy`, `coredns`, `aws-ebs-csi-driver` |

Console: EKS → Clusters → Create cluster → Custom configuration → set name, role, VPC, subnets, add-ons → Create.

---

## STEP-4  Create the node group

Terraform: `modules/eks` (`aws_eks_node_group.main`)

| Setting | Value |
|---|---|
| Name | `gitops-dev-node-group` |
| Node role | `gitops-dev-node-role` (AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly, AmazonSSMManagedInstanceCore) |
| Instance type | `c7i-flex.large`, ON_DEMAND |
| Subnets | private subnets only |
| Scaling | min **1**, desired **2**, max **3** |

To change the sizes, edit `envs/dev/terraform.tfvars` (`node_min_size`, `node_desired_size`, `node_max_size`) and push.

Console: EKS → gitops-dev → Compute → Add node group.

---

## STEP-5  OIDC provider for the cluster (IRSA)

Terraform: `modules/eks` (`aws_iam_openid_connect_provider.main`)

Lets Kubernetes service accounts assume IAM roles.

Console:
1. EKS → gitops-dev → Overview → copy **OpenID Connect provider URL**.
2. IAM → Identity providers → Add provider → **OpenID Connect**.
3. Provider URL = the OIDC URL, Audience = `sts.amazonaws.com` → Add provider.

---

## STEP-6  IAM role for a service account (example: AWS Load Balancer Controller)

Terraform: `modules/iam` → `irsa_roles` in `envs/dev/main.tf` (empty today; the EBS CSI role is in `modules/eks`)

Console:
1. IAM → Roles → Create role → **Web identity**.
2. Identity provider = the cluster OIDC provider, Audience = `sts.amazonaws.com`.
3. Edit the trust policy so it has both conditions (`<OIDC>` = URL without `https://`):

   | Condition | Key | Value |
   |---|---|---|
   | StringEquals | `<OIDC>:sub` | `system:serviceaccount:kube-system:aws-load-balancer-controller` |
   | StringEquals | `<OIDC>:aud` | `sts.amazonaws.com` |

4. Attach the controller's policy → name the role → Create role.

---

## STEP-7  Give your IAM user access to the cluster

Terraform: `cluster_admin_arns` in `envs/dev/terraform.tfvars`

Without this, `kubectl` says *"the server has asked for the client to provide credentials"* and the console shows
*"Unauthorized"* with **Nodes (0)**, even when the nodes are running.

```hcl
cluster_admin_arns = [
  "arn:aws:iam::772721871682:user/AccessKeyUser",
]
```

Each ARN gets an access entry with **AmazonEKSClusterAdminPolicy** (cluster scope).
Add the ARN of whichever user/role you sign in to the console with.

Console: EKS → gitops-dev → Access → Create access entry → IAM principal → add policy `AmazonEKSClusterAdminPolicy`, scope Cluster.

---

## STEP-8  Run the pipeline

1. Push changes under `envs/dev/` or `modules/` to `main`, or use Actions → **terraform-dev** → Run workflow (branch `main`).
2. Jobs run in order: **validate → plan → apply**. Apply runs only on `main`.
3. If the `dev` environment has reviewers, approve under **Review deployments**.

---

## STEP-9  Connect from your machine

```sh
aws sts get-caller-identity          # must be a principal from STEP-7
aws eks update-kubeconfig --region ap-south-1 --name gitops-dev
kubectl get nodes
```

Useful outputs (`terraform output` in `envs/dev`):

```sh
# Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Grafana on http://localhost:3000
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```

---

## STEP-10  Delete everything (save cost)

EKS, the NAT gateway and the Elastic IP are billed every hour.
Run Actions → **terraform-destroy** when dev isn't needed.
