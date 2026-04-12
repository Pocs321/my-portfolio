# =============================================================================
# ACM Certificate — HTTPS for custom domain
# Only created when domain_name is provided
# Must be in us-east-1 for CloudFront
# =============================================================================

resource "aws_acm_certificate" "cert" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-cert"
  }
}

# DNS validation records in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in(var.domain_name != "" ? aws_acm_certificate.cert[0].domain_validation_options : []) :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

# Wait for certificate validation to complete
resource "aws_acm_certificate_validation" "cert" {
  count    = var.domain_name != "" ? 1 : 0
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
