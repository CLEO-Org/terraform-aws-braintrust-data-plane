resource "aws_wafv2_web_acl" "brainstore" {
  count       = var.brainstore_enabled ? 1 : 0
  name        = "${var.deployment_name}-brainstore-web-acl"
  scope       = "CLOUDFRONT"
  description = "Brainstore Web ACL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.deployment_name}-brainstore"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
} 