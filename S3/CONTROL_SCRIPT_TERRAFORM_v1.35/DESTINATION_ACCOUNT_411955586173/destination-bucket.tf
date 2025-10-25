# Create destination bucket (same region as source)
resource "aws_s3_bucket" "destination" {
  bucket        = var.destination_bucket_name
  force_destroy = false

  tags = {
    Name           = "Same-Region Cross-Account Replication Destination"
    SourceAccount  = var.source_account_id
    ReplicationType = "Same-Region-Cross-Account"
    Environment    = "Production"
    ManagedBy      = "Terraform"
  }
}

# Enable versioning (REQUIRED for replication)
resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  bucket = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "destination" {
  bucket = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy allowing source account to replicate
resource "aws_s3_bucket_policy" "destination" {
  bucket = aws_s3_bucket.destination.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSourceAccountReplication"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:role/${var.source_replication_role_name}"
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.destination.arn}/*"
      },
      {
        Sid    = "AllowSourceAccountBucketAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:role/${var.source_replication_role_name}"
        }
        Action = [
          "s3:List*",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = aws_s3_bucket.destination.arn
      }
    ]
  })
}

# Lifecycle rules for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "destination" {
  bucket = aws_s3_bucket.destination.id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    filter {}
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

# Outputs
output "destination_bucket_name" {
  value       = aws_s3_bucket.destination.id
  description = "Destination bucket name"
}

output "destination_bucket_arn" {
  value       = aws_s3_bucket.destination.arn
  description = "Destination bucket ARN"
}

output "destination_bucket_region" {
  value       = var.AWS_REGION
  description = "Destination bucket region"
}

output "source_account_id" {
  value       = var.source_account_id
  description = "Source account ID"
}

