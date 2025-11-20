# ========================================
# Data Sources - Pull from Management Account SSM
# ========================================

# Get database password from existing SSM parameter
data "aws_ssm_parameter" "db_password" {
  provider = aws.management
  name     = "/enoch-blog/db-password"
}
