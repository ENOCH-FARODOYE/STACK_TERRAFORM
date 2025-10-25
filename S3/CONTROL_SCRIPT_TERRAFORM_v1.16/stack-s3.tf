

# Create S3 bucket with Object Lock enabled
# NOTE: Object Lock can only be enabled during bucket creation
resource "aws_s3_bucket" "object_lock" {
  bucket        = var.bucket_name
  force_destroy = false  # Cannot force destroy with Object Lock

  # Object Lock must be enabled at bucket creation
  object_lock_enabled = var.enable_object_lock
}

# Configure versioning (REQUIRED for Object Lock)
resource "aws_s3_bucket_versioning" "object_lock" {
  bucket = aws_s3_bucket.object_lock.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure default Object Lock retention
resource "aws_s3_bucket_object_lock_configuration" "object_lock" {
  count  = var.enable_object_lock ? 1 : 0
  bucket = aws_s3_bucket.object_lock.id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.object_lock]
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "object_lock" {
  bucket = aws_s3_bucket.object_lock.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "object_lock" {
  bucket = aws_s3_bucket.object_lock.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.object_lock.id
}

output "bucket_arn" {
  value = aws_s3_bucket.object_lock.arn
}

output "object_lock_enabled" {
  value = aws_s3_bucket.object_lock.object_lock_enabled
}

output "object_lock_mode" {
  value = var.enable_object_lock ? var.object_lock_mode : "Not enabled"
}

output "retention_days" {
  value = var.enable_object_lock ? var.retention_days : 0
}

