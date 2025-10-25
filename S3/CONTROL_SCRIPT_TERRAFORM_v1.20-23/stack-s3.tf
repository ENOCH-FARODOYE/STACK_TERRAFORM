

# Create S3 bucket
resource "aws_s3_bucket" "metadata" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "metadata" {
  bucket = aws_s3_bucket.metadata.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "metadata" {
  bucket = aws_s3_bucket.metadata.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "metadata" {
  bucket = aws_s3_bucket.metadata.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

