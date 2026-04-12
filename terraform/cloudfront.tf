# =============================================================================
# CloudFront Distribution — CDN for the static website
# =============================================================================

# Origin Access Control — secure way for CloudFront to access S3
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.project_name}-oac"
  description                       = "OAC for ${var.project_name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name} static website"
  default_root_object = var.default_root_object
  price_class         = var.cloudfront_price_class
  wait_for_deployment = false

  # Custom domain aliases (only if domain_name is provided)
  aliases = var.domain_name != "" ? [var.domain_name] : []

  # S3 Origin
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.website.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Use managed cache policy: CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Custom error responses — SPA-friendly: return index.html for 403/404
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  # SSL Certificate
  viewer_certificate {
    # If custom domain → use ACM cert; otherwise use default CloudFront cert
    acm_certificate_arn      = var.domain_name != "" ? aws_acm_certificate_validation.cert[0].certificate_arn : null
    cloudfront_default_certificate = var.domain_name == ""
    ssl_support_method       = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version = var.domain_name != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  # No geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "${var.project_name}-cdn"
  }
}
