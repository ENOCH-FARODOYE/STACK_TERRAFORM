# ========================================
# Data Sources
# ========================================

# Get database password from Management Account SSM
data "aws_ssm_parameter" "db_password" {
  provider = aws.management
  name     = "/enoch-blog/db-password"
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
