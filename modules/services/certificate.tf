# ACM Certificate for braintrust.prod-us-east-1.cleohealth.io
resource "aws_acm_certificate" "braintrust" {
  count             = var.custom_domain != null ? 1 : 0
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
  for_each = {
    for dvo in aws_acm_certificate.braintrust[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "braintrust" {
  count                   = var.custom_domain != null ? 1 : 0
  certificate_arn         = aws_acm_certificate.braintrust[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
} 