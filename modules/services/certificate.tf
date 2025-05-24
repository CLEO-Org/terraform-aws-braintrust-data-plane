# ACM Certificate for custom domain
resource "aws_acm_certificate" "braintrust" {
  count             = var.custom_domain != null && var.custom_certificate_arn == null ? 1 : 0
  domain_name       = var.custom_domain
  validation_method = "DNS"

  # Add wildcard subdomain for flexibility
  subject_alternative_names = ["*.${var.custom_domain}"]

  tags = merge(local.common_tags, {
    Service = "cloudfront"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records for the certificate
resource "aws_route53_record" "cert_validation" {
  for_each = var.custom_certificate_arn == null ? {
    for dvo in aws_acm_certificate.braintrust[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "braintrust" {
  count                   = var.custom_domain != null && var.custom_certificate_arn == null ? 1 : 0
  certificate_arn         = aws_acm_certificate.braintrust[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Local variable to determine which certificate ARN to use
locals {
  certificate_arn = var.custom_certificate_arn != null ? var.custom_certificate_arn : (var.custom_domain != null ? aws_acm_certificate.braintrust[0].arn : null)
}

# Output the certificate ARN for use in CloudFront
output "certificate_arn" {
  description = "The ARN of the certificate used by CloudFront"
  value       = local.certificate_arn
} 