##############################################################################
# Data Sources
##############################################################################

# Get available availability zones dynamically
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get current AWS account ID (Management Account)
data "aws_caller_identity" "current" {
  provider = aws.management
}

# Get current AWS region
data "aws_region" "current" {}

# Get Route53 hosted zone
data "aws_route53_zone" "main" {
  provider     = aws.management
  name         = var.route53_config.hosted_zone_name
  private_zone = false
}
