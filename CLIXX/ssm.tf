##############################################################################
# SSM Parameters - Management Account
# Will be accessed by Dev Account via cross-account role
##############################################################################

# EFS ID - placeholder, will be updated by Dev account
resource "aws_ssm_parameter" "efs_id" {
  name        = "/clixx/efs/id"
  description = "CliXX EFS File System ID"
  type        = "String"
  value       = "placeholder-will-be-updated-by-dev-account"

  tags = {
    Name        = "clixx-efs-id"
    Application = "CliXX"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

# RDS Endpoint - placeholder, will be updated by Dev account
resource "aws_ssm_parameter" "rds_endpoint" {
  name        = "/clixx/rds/endpoint"
  description = "CliXX RDS Database Endpoint"
  type        = "String"
  value       = "placeholder-will-be-updated-by-dev-account"

  tags = {
    Name        = "clixx-rds-endpoint"
    Application = "CliXX"
  }

  lifecycle {
    ignore_changes = [value]
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
