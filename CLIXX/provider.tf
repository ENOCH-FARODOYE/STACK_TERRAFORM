terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Default provider (Management account)
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "CliXX"
      Environment = "Management"
      ManagedBy   = "Terraform"
    }
  }
}

# Dev Account provider (assumes Engineer role)
provider "aws" {
  alias  = "dev"
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.dev_account_id}:role/Engineer"
    session_name = "terraform-clixx-dev"
  }

  default_tags {
    tags = {
      Project     = "CliXX"
      Environment = "Dev"
      ManagedBy   = "Terraform"
    }
  }
}
