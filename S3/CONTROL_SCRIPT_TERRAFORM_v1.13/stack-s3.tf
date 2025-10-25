

resource "aws_s3_bucket" "delete_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "delete_bucket_versioning" {
  bucket = aws_s3_bucket.delete_bucket.id
  versioning_configuration { status = "Enabled" }
}

output "bucket_name" { value = aws_s3_bucket.delete_bucket.id }
output "bucket_arn"  { value = aws_s3_bucket.delete_bucket.arn }
output "bucket_region" { value = var.AWS_REGION }

