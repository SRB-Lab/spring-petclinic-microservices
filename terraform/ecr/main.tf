# ─────────────────────────────────────────────────────────────────────────────
# ECR repositories — one per Spring PetClinic microservice
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # These names match the Maven module directories in the GitHub repo exactly.
  # DO NOT rename them — the build script derives ECR repo names from these.
  services = [
    "spring-petclinic-config-server",
    "spring-petclinic-discovery-server",
    "spring-petclinic-api-gateway",
    "spring-petclinic-customers-service",
    "spring-petclinic-visits-service",
    "spring-petclinic-vets-service",
    "spring-petclinic-admin-server",
    "spring-petclinic-genai-service",
  ]
}

# ── 1. Create one ECR repository per service ──────────────────────────────────
resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true   # free basic scan — catches known CVEs at push time
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Service     = each.value
    Environment = var.environment
  }
}

# ── 2. Lifecycle policy — keep costs and clutter under control ────────────────
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        # Keep the last N versioned images (tagged with v*)
        rulePriority = 1
        description  = "Keep last ${var.keep_last_n_images} versioned images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "build-"]
          countType     = "imageCountMoreThan"
          countNumber   = var.keep_last_n_images
        }
        action = { type = "expire" }
      },
      {
        # Remove dangling/untagged images after N days
        rulePriority = 2
        description  = "Expire untagged images after ${var.untagged_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_expiry_days
        }
        action = { type = "expire" }
      }
    ]
  })
}

# ── 3. IAM policy document — allows EKS worker nodes to pull from ECR ─────────
# Share this policy ARN with Infrastructure Engineer-3 so they can
# attach it to the EKS node IAM role.
data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull" {
  name        = "petclinic-ecr-pull-policy"
  description = "Allows EKS nodes to pull images from all PetClinic ECR repos"
  policy      = data.aws_iam_policy_document.ecr_pull.json
}

# ── 4. IAM policy for CI/CD pipeline — allows push ───────────────────────────
# Attach to the IAM user / role used by your Azure DevOps pipeline.
data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "AllowECRPush"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_push" {
  name        = "petclinic-ecr-push-policy"
  description = "Allows CI/CD pipeline user to build and push images to ECR"
  policy      = data.aws_iam_policy_document.ecr_push.json
}
