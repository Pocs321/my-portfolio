# =============================================================================
# IAM — GitHub Actions OIDC & Deployment Role
#
# Uses OIDC (OpenID Connect) instead of static access keys.
# This is the AWS-recommended approach for GitHub Actions:
#   - No long-lived credentials to rotate or leak
#   - Scoped to specific repo and branch
# =============================================================================

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# ---- GitHub OIDC Identity Provider ----
# This allows GitHub Actions to authenticate with AWS without access keys.
# Only ONE OIDC provider per account is needed — if you already have one,
# set create_oidc_provider = false (or import the existing one).

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name = "github-actions-oidc"
  }
}

# ---- IAM Role for GitHub Actions ----
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions"
  }
}

# ---- Policy: S3 Deployment ----
# Allows GitHub Actions to sync files to the S3 bucket
resource "aws_iam_role_policy" "s3_deploy" {
  name = "${var.project_name}-s3-deploy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.website.arn
      },
      {
        Sid    = "S3ManageObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# ---- Policy: CloudFront Invalidation ----
# Allows GitHub Actions to invalidate the CloudFront cache after deployment
resource "aws_iam_role_policy" "cloudfront_invalidation" {
  name = "${var.project_name}-cloudfront-invalidation"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations"
        ]
        Resource = aws_cloudfront_distribution.website.arn
      }
    ]
  })
}
