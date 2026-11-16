locals {
  repository_names = toset(var.repository_names)

  # Expire untagged images first, then cap the number of images kept per repo.
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
    ]
  })
}

# -----------------------------------------------------------------------------
# Repositories
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  for_each             = local.repository_names
  name                 = var.repository_prefix == "" ? each.value : "${var.repository_prefix}/${each.value}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn == "" ? "AES256" : "KMS"
    kms_key         = var.kms_key_arn == "" ? null : var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name = each.value
  })
}

# -----------------------------------------------------------------------------
# Lifecycle policies
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = var.enable_lifecycle_policy ? local.repository_names : toset([])
  repository = aws_ecr_repository.main[each.value].name
  policy     = local.lifecycle_policy
}

# -----------------------------------------------------------------------------
# Repository policies (optional cross-account / extra principal pull access)
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "pull" {
  count = length(var.pull_principal_arns) > 0 ? 1 : 0

  statement {
    sid = "AllowPull"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]

    principals {
      type        = "AWS"
      identifiers = var.pull_principal_arns
    }
  }
}

resource "aws_ecr_repository_policy" "main" {
  for_each   = length(var.pull_principal_arns) > 0 ? local.repository_names : toset([])
  repository = aws_ecr_repository.main[each.value].name
  policy     = data.aws_iam_policy_document.pull[0].json
}
