# ========================================
# AWS Provider - Cross-Account Setup
# Management Account → Dev Account
# ========================================
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  assume_role {
    role_arn = "arn:aws:iam::${var.dev_account_id}:role/Engineer"
  }

  default_tags {
    tags = {
      Project   = "EnochBlog"
      ManagedBy = "Terraform"
    }
  }
}

# ========================================
# Management Account Provider
# For SSM parameters only
# ========================================
provider "aws" {
  alias   = "management"
  region  = var.aws_region
  profile = var.aws_profile
}