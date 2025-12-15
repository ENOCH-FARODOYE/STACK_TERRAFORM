
# Or use sed to make the 
# change############################################################################## 
# Data Sources
sed -i 's/provider     = aws/provider     = aws/' datasources.tf##############################################################################

# Get available availability zones dynamically
data "aws_availability_zones" "available" {
  provider = aws.dev
  state    = "available"
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  provider    = aws.dev
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
  provider = aws
}

# Get current AWS region
data "aws_region" "current" {
  provider = aws
}

# Get Route53 hosted zone
data "aws_route53_zone" "main" {
  provider     = aws
  name         = var.route53_config.hosted_zone_name
  private_zone = false
}

# Read DB password from SSM Parameter Store
data "aws_ssm_parameter" "db_password" {
  name            = "/clixx/${var.environment}/db_password"
  with_decryption = true
}
