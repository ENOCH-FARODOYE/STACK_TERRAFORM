

# Create the S3 bucket
resource "aws_s3_bucket" "glacier" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "glacier" {
  bucket = aws_s3_bucket.glacier.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "glacier" {
  bucket = aws_s3_bucket.glacier.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy to transition to Glacier
resource "aws_s3_bucket_lifecycle_configuration" "glacier" {
  bucket = aws_s3_bucket.glacier.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 1
      storage_class = "GLACIER"
    }

    filter {
      prefix = "archive/"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "glacier" {
  bucket = aws_s3_bucket.glacier.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.glacier.id
}

output "bucket_arn" {
  value = aws_s3_bucket.glacier.arn
}

output "lifecycle_rule" {
  value = "Objects in 'archive/' prefix will transition to Glacier after 1 day"
}
