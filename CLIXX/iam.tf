##############################################################################
# IAM Role - Allows Dev Account Engineering Role to Access SSM Parameters
##############################################################################

# Get current account ID
data "aws_caller_identity" "current" {}

# Trust policy - allows Dev account engineering role to assume this role
data "aws_iam_policy_document" "ssm_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.dev_account_id}:role/${var.engineering_role_name}"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["clixx-ssm-access"]
    }
  }
}

# IAM Role
resource "aws_iam_role" "ssm_parameter_access" {
  name               = "SSMParameterAccessRole"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json

  tags = {
    Name        = "SSMParameterAccessRole"
    Application = "CliXX"
    Purpose     = "Allow Dev account to access CliXX SSM parameters"
  }
}

# Policy - allows reading and writing SSM parameters
data "aws_iam_policy_document" "ssm_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:PutParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/clixx/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
}

# Attach policy to role
resource "aws_iam_role_policy" "ssm_access_policy" {
  name   = "SSMParameterAccessPolicy"
  role   = aws_iam_role.ssm_parameter_access.id
  policy = data.aws_iam_policy_document.ssm_access_policy.json
}
