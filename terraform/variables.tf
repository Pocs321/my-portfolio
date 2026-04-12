# =============================================================================
# Input Variables
# =============================================================================

# ---- General ----
variable "aws_region" {
  description = "AWS region for the infrastructure"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name, used as prefix for resource naming"
  type        = string
  default     = "portfolio"
}

# ---- S3 ----
variable "bucket_name" {
  description = "S3 bucket name for the static website (must be globally unique)"
  type        = string
}

# ---- Domain & DNS ----
variable "domain_name" {
  description = "Custom domain name (e.g. portfolio.example.com). Leave empty to use CloudFront default domain."
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Set to true to create a new Route 53 hosted zone. Set to false if the zone already exists."
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID. Required if create_route53_zone = false and domain_name is set."
  type        = string
  default     = ""
}

# ---- GitHub Actions OIDC ----
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (e.g. 'myuser/my-portfolio')"
  type        = string
}

variable "github_branch" {
  description = "Branch that triggers deployment"
  type        = string
  default     = "main"
}

# ---- CloudFront ----
variable "cloudfront_price_class" {
  description = "CloudFront price class. Use PriceClass_100 for cheapest (US/EU only), PriceClass_200 for most regions, PriceClass_All for all edge locations."
  type        = string
  default     = "PriceClass_200"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "Must be one of: PriceClass_100, PriceClass_200, PriceClass_All"
  }
}

variable "default_root_object" {
  description = "Default root object for CloudFront (usually index.html)"
  type        = string
  default     = "index.html"
}
