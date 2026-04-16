# =============================================================================
# Route 53 — DNS Configuration
# Only created when domain_name is provided
# =============================================================================

# Resolve the hosted zone ID — either create new or use existing
locals {
  use_custom_domain = var.domain_name != ""

  # Use the full domain_name for the hosted zone
  # For Vietnamese domains like truonglab.id.vn, .id.vn is the TLD
  root_domain = local.use_custom_domain ? var.domain_name : ""

  zone_id = local.use_custom_domain ? (
    var.create_route53_zone
    ? aws_route53_zone.main[0].zone_id
    : var.route53_zone_id
  ) : ""
}

# Create a new hosted zone (optional)
resource "aws_route53_zone" "main" {
  count = local.use_custom_domain && var.create_route53_zone ? 1 : 0

  name    = local.root_domain
  comment = "Hosted zone for ${var.project_name}"

  tags = {
    Name = "${var.project_name}-zone"
  }
}

# A Record — point domain to CloudFront
resource "aws_route53_record" "website_a" {
  count = local.use_custom_domain ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

# AAAA Record — IPv6 support
resource "aws_route53_record" "website_aaaa" {
  count = local.use_custom_domain ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
