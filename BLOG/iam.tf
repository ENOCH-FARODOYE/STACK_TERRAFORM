# ========================================
# IAM Role for EC2 Instances
# ========================================
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-role"
  }
}

# ========================================
# IAM Policy for SSM Parameter Access
# ========================================
resource "aws_iam_role_policy" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.management_account_id}:parameter/${var.project_name}/*"
      },
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = "*"
      }
    ]
  })
}

# ========================================
# IAM Instance Profile
# ========================================
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}
