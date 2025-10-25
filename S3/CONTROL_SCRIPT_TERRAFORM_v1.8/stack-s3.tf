# Create the S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Configure static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  count  = var.enable_static_website ? 1 : 0
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# Allow public access for website hosting
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Enable versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.website.id
}

output "bucket_arn" {
  value = aws_s3_bucket.website.arn
}

output "website_endpoint" {
  value = var.enable_static_website ? aws_s3_bucket_website_configuration.website[0].website_endpoint : "Website hosting is DISABLED"
}

output "website_url" {
  value = var.enable_static_website ? "http://${aws_s3_bucket_website_configuration.website[0].website_endpoint}" : "Website hosting is DISABLED"
}

output "website_domain" {
  value = aws_s3_bucket.website.bucket_regional_domain_name
}

output "website_enabled" {
  value = var.enable_static_website
}
