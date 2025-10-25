
# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Create CloudTrail logs bucket
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = true
}

# Block public access to CloudTrail bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail bucket policy to allow CloudTrail service to write logs
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail_bucket]
}

# Create the main S3 bucket
resource "aws_s3_bucket" "main" {
  bucket        = var.bucket_name
  force_destroy = true
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

# Create CloudTrail for S3 data events
resource "aws_cloudtrail" "s3_trail" {
  count                         = var.enable_cloudtrail ? 1 : 0
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.main.arn}/*"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.main.id
}

output "bucket_arn" {
  value = aws_s3_bucket.main.arn
}

output "cloudtrail_bucket_name" {
  value = aws_s3_bucket.cloudtrail_bucket.id
}

output "cloudtrail_bucket_arn" {
  value = aws_s3_bucket.cloudtrail_bucket.arn
}

output "cloudtrail_name" {
  value = var.enable_cloudtrail ? aws_cloudtrail.s3_trail[0].name : "CloudTrail is DISABLED"
}

output "cloudtrail_arn" {
  value = var.enable_cloudtrail ? aws_cloudtrail.s3_trail[0].arn : "N/A"
}

output "cloudtrail_enabled" {
  value = var.enable_cloudtrail
}

output "cloudtrail_configuration" {
  value = var.enable_cloudtrail ? "CloudTrail is logging S3 object events to s3://${aws_s3_bucket.cloudtrail_bucket.id}" : "CloudTrail is DISABLED"
}
