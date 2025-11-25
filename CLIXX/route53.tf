##############################################################################
# Route 53 DNS - Dev Account
##############################################################################

# Data source - existing hosted zone for enoch-stack.com
data "aws_route53_zone" "main" {
  provider = aws

  name         = "enoch-stack.com"
  private_zone = false
}

# A Record - points dev.clixx subdomain to ALB
resource "aws_route53_record" "clixx_dev" {
  provider = aws

  zone_id = data.aws_route53_zone.main.zone_id
  name    = "dev.clixx.enoch-stack.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
