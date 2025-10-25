

# Create S3 bucket
resource "aws_s3_bucket" "versioned" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "versioned" {
  bucket = aws_s3_bucket.versioned.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "versioned" {
  bucket = aws_s3_bucket.versioned.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "versioned" {
  bucket = aws_s3_bucket.versioned.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.versioned.id
}

output "bucket_arn" {
  value = aws_s3_bucket.versioned.arn
}

output "versioning_status" {
  value = var.enable_versioning ? "Enabled" : "Suspended"
}
