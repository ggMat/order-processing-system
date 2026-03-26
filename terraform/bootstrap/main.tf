terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # intentional: local state because this runs once from a developer laptop 
  backend "local" {}
}

provider "aws" {
  region = var.aws_region
}

# ──────────────────────────────────────────
# S3 state buckets
# ──────────────────────────────────────────

module "tfstate_dev" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${var.project_name}-tfstate-dev"

  # Prevent destroy
  force_destroy = false

  lifecycle_rule = []

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "tfstate_prod" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0"

  bucket = "${var.project_name}-tfstate-prod"

  # Prevent destroy
  force_destroy = false

  lifecycle_rule = []

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────
# DynamoDB lock tables
# ──────────────────────────────────────────

resource "aws_dynamodb_table" "lock_dev" {
  name         = "${var.project_name}-tfstate-lock-dev"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "lock_prod" {
  name         = "${var.project_name}-tfstate-lock-prod"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# ──────────────────────────────────────────
# GitHub Actions OIDC
# ──────────────────────────────────────────

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::405989524795:oidc-provider/token.actions.githubusercontent.com"
}
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

#TODO: Implement least privilege policy in a real production system
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" 
}
