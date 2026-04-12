# =============================================================================
# Outputs — Important values after terraform apply
# =============================================================================

# ---- S3 ----
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "s3_website_endpoint" {
  description = "S3 static website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

# ---- CloudFront ----
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "The URL to access the website"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

# ---- IAM ----
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions (use in workflow)"
  value       = aws_iam_role.github_actions.arn
}

# ---- Route 53 ----
output "route53_nameservers" {
  description = "Nameservers for the hosted zone (update at your domain registrar)"
  value       = var.domain_name != "" && var.create_route53_zone ? aws_route53_zone.main[0].name_servers : []
}

# ---- Summary for GitHub Actions config ----
output "github_actions_config" {
  description = "Values to configure in GitHub Actions workflow"
  value = {
    role_arn        = aws_iam_role.github_actions.arn
    aws_region      = var.aws_region
    s3_bucket       = aws_s3_bucket.website.id
    distribution_id = aws_cloudfront_distribution.website.id
  }
}
