# ========================================
# SSM Parameters in Management Account
# ========================================

# EFS File System ID
resource "aws_ssm_parameter" "efs_id" {
  provider = aws.management
  name     = "/${var.project_name}/efs-id"
  type     = "String"
  value    = aws_efs_file_system.wordpress.id

  tags = {
    Name = "${var.project_name}-efs-id"
  }
}

# RDS Endpoint
resource "aws_ssm_parameter" "rds_endpoint" {
  provider = aws.management
  name     = "/${var.project_name}/rds-endpoint"
  type     = "String"
  value    = aws_db_instance.wordpress.endpoint

  tags = {
    Name = "${var.project_name}-rds-endpoint"
  }
}

# Database Name
resource "aws_ssm_parameter" "db_name" {
  provider = aws.management
  name     = "/${var.project_name}/db-name"
  type     = "String"
  value    = var.db_name

  tags = {
    Name = "${var.project_name}-db-name"
  }
}

# Database Username
resource "aws_ssm_parameter" "db_username" {
  provider = aws.management
  name     = "/${var.project_name}/db-username"
  type     = "SecureString"
  value    = var.db_username

  tags = {
    Name = "${var.project_name}-db-username"
  }
}

# ALB DNS Name
resource "aws_ssm_parameter" "alb_dns" {
  provider = aws.management
  name     = "/${var.project_name}/alb-dns"
  type     = "String"
  value    = aws_lb.main.dns_name

  tags = {
    Name = "${var.project_name}-alb-dns"
  }
}
