
# IAM Role for Cross-Account Replication
resource "aws_iam_role" "replication_crossaccount" {
  name = "s3-replication-role-enoch-v125-crossaccount"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "Cross-Account S3 Replication Role"
    Environment = "Production"
  }
}

# IAM Policy for Cross-Account Replication
resource "aws_iam_role_policy" "replication_crossaccount" {
  name = "s3-replication-policy-crossaccount"
  role = aws_iam_role.replication_crossaccount.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "SourceBucketPermissions"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.source.arn
        ]
      },
      {
        Sid = "SourceObjectPermissions"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.source.arn}/*"
        ]
      },
      {
        Sid = "DestinationBucketPermissions"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.cross_account_destination_bucket}/*"
        ]
      }
    ]
  })
}

# Outputs for Cross-Account Replication
output "crossaccount_replication_role_arn" {
  value       = aws_iam_role.replication_crossaccount.arn
  description = "ARN of cross-account replication role"
}

output "crossaccount_destination_bucket" {
  value       = var.cross_account_destination_bucket
  description = "Cross-account destination bucket name"
}

output "destination_account_id" {
  value       = var.destination_account_id
  description = "Destination AWS account ID"
}
