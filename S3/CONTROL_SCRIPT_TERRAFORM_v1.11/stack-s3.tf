

# Create the S3 bucket for uploads
resource "aws_s3_bucket" "upload" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "upload" {
  bucket = aws_s3_bucket.upload.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "upload" {
  bucket = aws_s3_bucket.upload.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "upload" {
  bucket = aws_s3_bucket.upload.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.upload.id
}

output "bucket_arn" {
  value = aws_s3_bucket.upload.arn
}

output "bucket_region" {
  value = var.AWS_REGION
}
