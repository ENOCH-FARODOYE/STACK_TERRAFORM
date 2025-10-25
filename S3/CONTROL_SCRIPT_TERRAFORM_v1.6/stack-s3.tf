

# Create the logging destination bucket
resource "aws_s3_bucket" "log_bucket" {
  bucket        = var.log_bucket_name
  force_destroy = true
}

# Block public access to log bucket
resource "aws_s3_bucket_public_access_block" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Grant S3 Log Delivery permissions to write logs
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.log_bucket.arn}/${var.log_prefix}*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.log_bucket]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Create the main S3 bucket
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Configure server access logging
resource "aws_s3_bucket_logging" "main" {
  count  = var.enable_server_logging ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = var.log_prefix
}

# Enable versioning on main bucket
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption on main bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to main bucket
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

output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.id
}

output "log_bucket_arn" {
  value = aws_s3_bucket.log_bucket.arn
}

output "log_prefix" {
  value = var.log_prefix
}

output "logging_enabled" {
  value = var.enable_server_logging
}

output "logging_configuration" {
  value = var.enable_server_logging ? "Logs are being written to s3://${aws_s3_bucket.log_bucket.id}/${var.log_prefix}" : "Logging is DISABLED"
}
