resource "aws_wafv2_web_acl" "brainstore" {
  count       = var.brainstore_enabled ? 1 : 0
  name        = "${var.deployment_name}-brainstore-web-acl"
  scope       = "CLOUDFRONT"
  description = "Brainstore Web ACL"

  default_action {
    allow {}
  }

  rule {
    name     = "AllowIP"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowlist.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.deployment_name}-brainstore"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_wafv2_ip_set" "allowlist" {
  name               = "${var.deployment_name}-allowlist"
  description        = "IP allowlist for Brainstore"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = ["51.8.205.26/32"]

  provider = aws.us-east-1

  tags = local.common_tags

  lifecycle {
    ignore_changes = [addresses]
  }
} 