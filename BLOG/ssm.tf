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
#resource "aws_ssm_parameter" "rds_endpoint" {
 # provider = aws.management
  #name     = "/${var.project_name}/rds-endpoint"
  #type     = "String"
  #value    = aws_db_instance.wordpress.address

  #tags = {
   # Name = "${var.project_name}-rds-endpoint"
#  }
#}
# Using null_resource to bypass SSM bug
resource "null_resource" "rds_endpoint_parameter" {
  triggers = {
    rds_address = aws_db_instance.wordpress.address
  }

  provisioner "local-exec" {
    command = "aws ssm put-parameter --name /enoch-blog/rds-endpoint --value ${aws_db_instance.wordpress.address} --type String --overwrite --region us-east-1 --profile stack_admin_enoch"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ssm delete-parameter --name /enoch-blog/rds-endpoint --region us-east-1 --profile stack_admin_enoch || true"
  }

  depends_on = [aws_db_instance.wordpress]
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
  type     = "String"
  value    = var.db_username

  tags = {
    Name = "${var.project_name}-db-username"
  }
}

# Database Password
resource "aws_ssm_parameter" "db_password" {
  provider = aws.management
  name     = "/${var.project_name}/db-password"
  type     = "SecureString"
  value    = var.db_password
  overwrite = true

  tags = {
    Name = "${var.project_name}-db-password"
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

# Update existing db_password resource with lifecycle
