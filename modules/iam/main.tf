locals {
  # GitHub Actions OIDC issuer and the audience aws-actions/configure-aws-credentials requests.
  github_oidc_host = "token.actions.githubusercontent.com"
  github_audience  = "sts.amazonaws.com"

  github_oidc_provider_arn = var.create_github_oidc_provider ? try(aws_iam_openid_connect_provider.github[0].arn, null) : try(data.aws_iam_openid_connect_provider.github[0].arn, null)

  # Default to "any branch/tag/PR/environment of the listed repos" when no explicit subjects are given.
  # Covers both the legacy sub (repo:owner/repo:...) and the ID form (repo:owner@123/repo@456:...).
  github_subjects = length(var.github_subjects) > 0 ? var.github_subjects : flatten([
    for repo in var.github_repositories : [
      "repo:${repo}:*",
      "repo:${split("/", repo)[0]}@*/${split("/", repo)[1]}@*:*",
    ]
  ])
}

data "aws_partition" "current" {}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC provider (one per AWS account; usually owned by bootstrap/)
# -----------------------------------------------------------------------------
data "tls_certificate" "github" {
  count = var.enable_github_actions_role && var.create_github_oidc_provider ? 1 : 0
  url   = "https://${local.github_oidc_host}"
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.enable_github_actions_role && var.create_github_oidc_provider ? 1 : 0
  url             = "https://${local.github_oidc_host}"
  client_id_list  = [local.github_audience]
  thumbprint_list = [data.tls_certificate.github[0].certificates[0].sha1_fingerprint]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-oidc"
  })
}

# Reuse the provider when bootstrap/ (or another env in this account) already created it.
data "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_actions_role && !var.create_github_oidc_provider ? 1 : 0
  url   = "https://${local.github_oidc_host}"
}

# -----------------------------------------------------------------------------
# GitHub Actions role (build + push images to ECR)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "github_assume_role" {
  count = var.enable_github_actions_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = [local.github_audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.github_subjects
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count                = var.enable_github_actions_role ? 1 : 0
  name                 = "${var.name_prefix}-github-actions-role"
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role[0].json
  max_session_duration = 3600

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-github-actions-role"
  })
}

data "aws_iam_policy_document" "github_ecr_push" {
  count = var.enable_github_actions_role ? 1 : 0

  statement {
    sid       = "EcrAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []

    content {
      sid = "EcrPushPull"

      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
      ]

      resources = var.ecr_repository_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.eks_cluster_arns) > 0 ? [1] : []

    content {
      sid       = "EksDescribe"
      actions   = ["eks:DescribeCluster"]
      resources = var.eks_cluster_arns
    }
  }
}

resource "aws_iam_role_policy" "github_ecr_push" {
  count  = var.enable_github_actions_role ? 1 : 0
  name   = "${var.name_prefix}-github-ecr-push"
  role   = aws_iam_role.github_actions[0].id
  policy = data.aws_iam_policy_document.github_ecr_push[0].json
}

# Keep state addresses from the GitLab version (the role is still replaced because its name changed).
moved {
  from = aws_iam_role.gitlab_ci
  to   = aws_iam_role.github_actions
}

moved {
  from = aws_iam_role_policy.gitlab_ecr_push
  to   = aws_iam_role_policy.github_ecr_push
}

# -----------------------------------------------------------------------------
# IRSA roles (one per in-cluster service account)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "irsa_assume_role" {
  for_each = var.irsa_roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.eks_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_issuer}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "irsa" {
  for_each           = var.irsa_roles
  name               = "${var.name_prefix}-${each.key}-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role[each.key].json

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.key}-irsa-role"
  })
}

resource "aws_iam_role_policy_attachment" "irsa" {
  for_each = {
    for pair in flatten([
      for role, cfg in var.irsa_roles : [
        # Key by index so policy ARNs created in the same apply don't break for_each.
        for idx, arn in cfg.policy_arns : { key = "${role}-${idx}", role = role, arn = arn }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.irsa[each.value.role].name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy" "irsa_inline" {
  for_each = { for role, cfg in var.irsa_roles : role => cfg if cfg.inline_policy != null }
  name     = "${var.name_prefix}-${each.key}-inline"
  role     = aws_iam_role.irsa[each.key].id
  policy   = each.value.inline_policy
}
