


# S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Bucket Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# Default Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.encryption_enabled ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_type == "SSE-KMS" ? "aws:kms" : "AES256"
      kms_master_key_id = var.encryption_type == "SSE-KMS" ? var.kms_key_id : null
    }
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.main.id
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "bucket_versioning_status" {
  value = aws_s3_bucket_versioning.main.versioning_configuration[0].status
}

output "bucket_encryption_type" {
  value = var.encryption_enabled ? var.encryption_type : "None"
}

