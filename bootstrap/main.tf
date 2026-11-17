locals {
  # Terraform state bucket name. S3 names are global: must be unique across all AWS accounts.
  # If you change it, also update bucket in envs/dev/backend.tf and envs/prod/backend.tf.
  state_bucket_name = "asthira-tfstate-dev"

  # GitHub Actions OIDC issuer and the audience aws-actions/configure-aws-credentials requests.
  github_oidc_host = "token.actions.githubusercontent.com"
  github_audience  = "sts.amazonaws.com"

  terraform_ci_subjects = length(var.terraform_ci_subjects) > 0 ? var.terraform_ci_subjects : [
    "repo:${var.github_infra_repo}:*"
  ]
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Terraform state bucket (locking via S3 lock files, no DynamoDB needed)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  tags = {
    Name = local.state_bucket_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_state_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}

# -----------------------------------------------------------------------------
# GitHub Actions OIDC provider (shared by every env in this account)
# -----------------------------------------------------------------------------
data "tls_certificate" "github" {
  url = "https://${local.github_oidc_host}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://${local.github_oidc_host}"
  client_id_list  = [local.github_audience]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name = "${var.project_name}-github-oidc"
  }
}

# -----------------------------------------------------------------------------
# Terraform CI role (assumed by this repo's GitHub Actions workflows)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "terraform_ci_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = [local.github_audience]
    }

    condition {
      test     = "StringLike"
      variable = "${local.github_oidc_host}:sub"
      values   = local.terraform_ci_subjects
    }
  }
}

resource "aws_iam_role" "terraform_ci" {
  name                 = "${var.project_name}-terraform-ci-role"
  assume_role_policy   = data.aws_iam_policy_document.terraform_ci_assume_role.json
  max_session_duration = 7200

  tags = {
    Name = "${var.project_name}-terraform-ci-role"
  }
}

resource "aws_iam_role_policy_attachment" "terraform_ci" {
  for_each   = toset(var.terraform_ci_policy_arns)
  role       = aws_iam_role.terraform_ci.name
  policy_arn = each.value
}
