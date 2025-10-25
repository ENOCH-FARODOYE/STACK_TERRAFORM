# Create S3 bucket (source)
resource "aws_s3_bucket" "source" {
  bucket        = var.bucket_name
  force_destroy = false
}

# Enable versioning (required for replication)
resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (Story 30)
resource "aws_s3_bucket_public_access_block" "source" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Transfer Acceleration (Story 35)
resource "aws_s3_bucket_accelerate_configuration" "source" {
  count  = var.enable_transfer_acceleration ? 1 : 0
  bucket = aws_s3_bucket.source.id
  status = "Enabled"
}

# Lifecycle Configuration (Story 26)
resource "aws_s3_bucket_lifecycle_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    id     = "archive-old-objects"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    filter {
      prefix = "archive/"
    }
  }

  rule {
    id     = "delete-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {}
  }
}

# IAM Role for Replication (Story 27)
resource "aws_iam_role" "replication" {
  name = "s3-replication-role-enoch-v125"

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
}

resource "aws_iam_role_policy" "replication" {
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.destination.arn}/*"
        ]
      }
    ]
  })
}

# Outputs
output "source_bucket_name" {
  value = aws_s3_bucket.source.id
}

output "source_bucket_arn" {
  value = aws_s3_bucket.source.arn
}

output "destination_bucket_name" {
  value = aws_s3_bucket.destination.id
}

output "destination_bucket_arn" {
  value = aws_s3_bucket.destination.arn
}

output "replication_role_arn" {
  value = aws_iam_role.replication.arn
}

output "transfer_acceleration_status" {
  value = var.enable_transfer_acceleration ? "Enabled" : "Disabled"
}
