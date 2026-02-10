##############################################################################
# AWS Providers - Management and Dev Accounts
##############################################################################

# Management Account Provider (for Route53, SSM)
provider "aws" {
  region = var.environment_config.aws_region
  
  assume_role {
    role_arn     = "arn:aws:iam::978820380225:role/TerraformManagementAccess"
    session_name = "terraform-clixx"
  }
  
  default_tags {
    tags = merge(
      var.common_tags,
      {
        Account = "Management"
      }
    )
  }
}

# Dev Account Provider (assumes Engineer role)
provider "aws" {
  alias  = "dev"
  region = var.environment_config.aws_region
  
  assume_role {
    role_arn     = "arn:aws:iam::${var.environment_config.dev_account_id}:role/${var.environment_config.engineering_role_name}"
    session_name = "terraform-${var.environment_config.project_name}-${var.environment}"
  }
  
  default_tags {
    tags = merge(
      var.common_tags,
      {
        Account = "Dev"
      }
    )
  }
}
