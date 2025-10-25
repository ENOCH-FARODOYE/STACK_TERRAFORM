# Create destination bucket for replication
resource "aws_s3_bucket" "destination" {
  provider      = aws.destination
  bucket        = var.destination_bucket_name
  force_destroy = false
}

# Enable versioning on destination
resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on destination
resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access on destination
resource "aws_s3_bucket_public_access_block" "destination" {
  provider = aws.destination
  bucket   = aws_s3_bucket.destination.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
