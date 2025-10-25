

# Create the S3 bucket
resource "aws_s3_bucket" "undelete" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable versioning (REQUIRED for undelete)
resource "aws_s3_bucket_versioning" "undelete" {
  bucket = aws_s3_bucket.undelete.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "undelete" {
  bucket = aws_s3_bucket.undelete.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "undelete" {
  bucket = aws_s3_bucket.undelete.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.undelete.id
}

output "bucket_arn" {
  value = aws_s3_bucket.undelete.arn
}

output "versioning_enabled" {
  value = "Enabled"
}

output "bucket_region" {
  value = var.AWS_REGION
}
