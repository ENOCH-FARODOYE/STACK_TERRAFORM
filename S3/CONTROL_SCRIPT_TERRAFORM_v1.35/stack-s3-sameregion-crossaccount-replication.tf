# IAM Role for Same-Region Cross-Account Replication
resource "aws_iam_role" "replication_sameregion_crossaccount" {
  name = "s3-replication-role-enoch-v125-sameregion-crossaccount"

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
    Name            = "Same-Region Cross-Account S3 Replication Role"
    ReplicationType = "Same-Region-Cross-Account"
    Environment     = "Production"
    ManagedBy       = "Terraform"
  }
}

# IAM Policy for Same-Region Cross-Account Replication
resource "aws_iam_role_policy" "replication_sameregion_crossaccount" {
  name = "s3-replication-policy-sameregion-crossaccount"
  role = aws_iam_role.replication_sameregion_crossaccount.id

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
          "arn:aws:s3:::${var.sameregion_crossaccount_destination_bucket}/*"
        ]
      }
    ]
  })
}

# Outputs for Same-Region Cross-Account Replication
output "sameregion_crossaccount_replication_role_arn" {
  value       = aws_iam_role.replication_sameregion_crossaccount.arn
  description = "ARN of same-region cross-account replication role"
}

output "sameregion_crossaccount_destination_bucket" {
  value       = var.sameregion_crossaccount_destination_bucket
  description = "Same-region cross-account destination bucket name"
}

