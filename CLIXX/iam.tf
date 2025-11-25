##############################################################################
# IAM Roles - Management Account SSM Access + Dev Account EC2 Role
##############################################################################

# Get current account ID
data "aws_caller_identity" "current" {}

##############################################################################
# MANAGEMENT ACCOUNT - SSM Parameter Access Role
##############################################################################

# Trust policy - allows Dev account roles to assume this role
data "aws_iam_policy_document" "ssm_assume_role" {
  # Allow Dev account Engineering role
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

  # Allow Dev account EC2 role - depends on EC2 role existing
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ec2_instance.arn]  # Changed to reference ARN
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["clixx-ssm-access"]
    }
  }
}

# IAM Role - Management Account
resource "aws_iam_role" "ssm_parameter_access" {
  name               = "SSMParameterAccessRole"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json

  tags = {
    Name        = "SSMParameterAccessRole"
    Application = "CliXX"
    Purpose     = "Allow Dev account to access CliXX SSM parameters"
  }

  depends_on = [aws_iam_role.ec2_instance]  # Added dependency
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

##############################################################################
# DEV ACCOUNT - EC2 Instance Role
##############################################################################

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance" {
  provider = aws.dev

  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# Policy - allows assuming Management Account SSM role
resource "aws_iam_role_policy" "assume_mgmt_ssm_role" {
  provider = aws.dev

  name = "${var.project_name}-assume-mgmt-ssm-policy"
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "arn:aws:iam::${var.management_account_id}:role/SSMParameterAccessRole"
      }
    ]
  })
}

# Policy - basic EC2 permissions (CloudWatch, SSM Session Manager)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  provider = aws.dev

  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  provider = aws.dev

  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  provider = aws.dev

  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Name = "${var.project_name}-ec2-instance-profile"
  }
}
