# =============================================================================
# Project 1 — Static Website CI/CD Pipeline
# Stack: GitHub → GitHub Actions → S3 → CloudFront → Route 53
#
# This Terraform configuration provisions:
#   - S3 bucket for static website hosting
#   - CloudFront CDN distribution with OAC
#   - ACM SSL certificate (DNS validated)
#   - Route 53 DNS records
#   - IAM role for GitHub Actions (OIDC)
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ---- Optional: Remote state in S3 ----
  # Uncomment the block below after creating the state bucket manually:
  #   aws s3api create-bucket --bucket <your-tf-state-bucket> --region ap-southeast-1 \
  #     --create-bucket-configuration LocationConstraint=ap-southeast-1
  #
  # backend "s3" {
  #   bucket  = "your-tf-state-bucket"
  #   key     = "project1/terraform.tfstate"
  #   region  = "ap-southeast-1"
  #   encrypt = true
  # }
}

# Primary provider — region from variable
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "static-website-cicd"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

# ACM certificates for CloudFront MUST be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "static-website-cicd"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}
