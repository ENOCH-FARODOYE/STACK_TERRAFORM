



# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Create SQS queue for S3 notifications
resource "aws_sqs_queue" "s3_notifications" {
  name                       = var.sqs_queue_name
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  delay_seconds             = 0
  receive_wait_time_seconds = 10
}

# SQS queue policy to allow S3 to send messages
resource "aws_sqs_queue_policy" "s3_notifications_policy" {
  queue_url = aws_sqs_queue.s3_notifications.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ToSendMessage"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.s3_notifications.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_s3_bucket.notifications.arn
          }
        }
      }
    ]
  })
}

# Create the S3 bucket
resource "aws_s3_bucket" "notifications" {
  bucket        = var.bucket_name
  force_destroy = true
}

# Configure S3 event notifications
resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.enable_event_notifications ? 1 : 0
  bucket = aws_s3_bucket.notifications.id

  queue {
    queue_arn     = aws_sqs_queue.s3_notifications.arn
    events        = var.notification_events
    filter_prefix = var.filter_prefix
    filter_suffix = var.filter_suffix
  }

  depends_on = [aws_sqs_queue_policy.s3_notifications_policy]
}

# Enable versioning
resource "aws_s3_bucket_versioning" "notifications" {
  bucket = aws_s3_bucket.notifications.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "notifications" {
  bucket = aws_s3_bucket.notifications.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "notifications" {
  bucket = aws_s3_bucket.notifications.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "bucket_name" {
  value = aws_s3_bucket.notifications.id
}

output "bucket_arn" {
  value = aws_s3_bucket.notifications.arn
}

output "sqs_queue_name" {
  value = aws_sqs_queue.s3_notifications.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.s3_notifications.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.s3_notifications.arn
}

output "notification_events" {
  value = var.notification_events
}

output "notifications_enabled" {
  value = var.enable_event_notifications
}

output "notification_configuration" {
  value = var.enable_event_notifications ? "S3 events are being sent to SQS queue: ${aws_sqs_queue.s3_notifications.name}" : "Notifications are DISABLED"
}
