# ========================================
# Get Hosted Zone (if zone ID not provided)
# ========================================
data "aws_route53_zone" "main" {
  provider     = aws.management
  count        = var.hosted_zone_id == "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# ========================================
# Route53 A Record (Alias to ALB)
# ========================================
resource "aws_route53_record" "main" {
  provider = aws.management
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
