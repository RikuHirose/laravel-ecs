locals {
  origin_id  = "ELB-${var.name}"
}


# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution
resource "aws_cloudfront_distribution" "this" {
  enabled         = true
  is_ipv6_enabled = true
  aliases         = [var.domain]

  origin {
    domain_name = var.alb_dns_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.acm_id
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["HEAD", "GET", "OPTIONS"]
    target_origin_id = local.origin_id
    compress         = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }

      headers = ["Accept", "Accept-Language", "Authorization", "CloudFront-Forwarded-Proto", "Host", "Origin", "Referer", "User-agent"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    max_ttl                = 0
    default_ttl            = 0
  }

  # logging_config {
  #   bucket          = "adachin-web-cf-logs.s3.amazonaws.com"
  #   include_cookies = "true"
  #   prefix          = "[CF] adachin-web.com/"
  # }
}

data "aws_route53_zone" "this" {
  name         = var.domain
  private_zone = false
}

resource "aws_route53_record" "this" {
  type = "A"

  name    = var.domain
  zone_id = data.aws_route53_zone.this.id

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}