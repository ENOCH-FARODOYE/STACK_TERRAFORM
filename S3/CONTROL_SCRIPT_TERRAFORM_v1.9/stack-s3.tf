

# Create the S3 bucket for redirect
resource "aws_s3_bucket" "redirect" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Configure website redirect to another host
resource "aws_s3_bucket_website_configuration" "redirect" {
  count  = var.enable_website_redirect ? 1 : 0
  bucket = aws_s3_bucket.redirect.id

  redirect_all_requests_to {
    host_name = var.redirect_target_host
    protocol  = var.redirect_protocol
  }
}

# Allow public access for website redirect
resource "aws_s3_bucket_public_access_block" "redirect" {
  bucket = aws_s3_bucket.redirect.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access
resource "aws_s3_bucket_policy" "redirect_policy" {
  bucket = aws_s3_bucket.redirect.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.redirect.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.redirect]
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.redirect.id
}

output "bucket_arn" {
  value = aws_s3_bucket.redirect.arn
}

output "redirect_endpoint" {
  value = var.enable_website_redirect ? aws_s3_bucket_website_configuration.redirect[0].website_endpoint : "Redirect is DISABLED"
}

output "redirect_url" {
  value = var.enable_website_redirect ? "http://${aws_s3_bucket_website_configuration.redirect[0].website_endpoint}" : "Redirect is DISABLED"
}

output "redirect_target" {
  value = var.enable_website_redirect ? "${var.redirect_protocol}://${var.redirect_target_host}" : "N/A"
}

output "redirect_configuration" {
  value = var.enable_website_redirect ? "All requests to http://${aws_s3_bucket_website_configuration.redirect[0].website_endpoint} will redirect to ${var.redirect_protocol}://${var.redirect_target_host}" : "Redirect is DISABLED"
}
