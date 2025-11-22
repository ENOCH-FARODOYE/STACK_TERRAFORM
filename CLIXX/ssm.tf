##############################################################################
# SSM Parameters - Management Account
# Automatically populated from Dev Account resources
##############################################################################

# EFS ID - Direct reference from Dev account EFS
resource "aws_ssm_parameter" "efs_id" {
  name        = "/clixx/efs/id"
  description = "CliXX EFS File System ID"
  type        = "String"
  value       = aws_efs_file_system.main.id

  tags = {
    Name        = "clixx-efs-id"
    Application = "CliXX"
  }
}

# RDS Endpoint - Direct reference from Dev account RDS
resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/clixx/rds/endpoint"
  description = "CliXX RDS Database Endpoint"
  type        = "String"
  value       = aws_db_instance.main.endpoint

  tags = {
    Name        = "clixx-rds-endpoint"
    Application = "CliXX"
  }
}

# Database Name
resource "aws_ssm_parameter" "db_name" {
  name        = "/clixx/rds/database"
  description = "CliXX Database Name"
  type        = "String"
  value       = var.db_name

  tags = {
    Name        = "clixx-db-name"
    Application = "CliXX"
  }
}

# Database Username
resource "aws_ssm_parameter" "db_username" {
  name        = "/clixx/rds/username"
  description = "CliXX Database Username"
  type        = "String"
  value       = var.db_username

  tags = {
    Name        = "clixx-db-username"
    Application = "CliXX"
  }
}

# Database Password (SecureString)
resource "aws_ssm_parameter" "db_password" {
  name        = "/clixx/rds/password"
  description = "CliXX Database Password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Name        = "clixx-db-password"
    Application = "CliXX"
  }
}
