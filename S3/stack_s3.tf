# ===================================
# COMPLETE AWS S3 OPERATIONS STACK
# ===================================
# This file demonstrates ALL S3 operations in one configuration

# ===================================
# 1. LOGS BUCKET (for Server Access Logging)
# ===================================
resource "aws_s3_bucket" "logs" {
  bucket        = var.logs_bucket_name
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.logs_bucket_name
      Type = "Logs"
    }
  )
}

# Logs Bucket - Ownership Controls (required for ACL)
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Logs Bucket - ACL for log delivery
resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

# Logs Bucket - Public Access Block
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logs Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ===================================
# 2. ANALYTICS BUCKET (for Storage Class Analysis)
# ===================================
resource "aws_s3_bucket" "analytics" {
  bucket        = var.analytics_bucket_name
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.analytics_bucket_name
      Type = "Analytics"
    }
  )
}

# Analytics Bucket - Public Access Block
resource "aws_s3_bucket_public_access_block" "analytics" {
  bucket = aws_s3_bucket.analytics.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Analytics Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "analytics" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.analytics.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ===================================
# 3. MAIN BUCKET (with ALL features)
# ===================================
resource "aws_s3_bucket" "main" {
  bucket        = var.main_bucket_name
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.main_bucket_name
      Type = "Main"
    }
  )
}

# ===================================
# VERSIONING - Enable/Suspend Versioning
# ===================================
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ===================================
# ENCRYPTION - Enable Default Encryption
# ===================================
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ===================================
# PUBLIC ACCESS BLOCK - Block Public Access
# ===================================
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===================================
# ACL - Set Bucket Permissions
# ===================================
resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "main" {
  depends_on = [aws_s3_bucket_ownership_controls.main]
  bucket     = aws_s3_bucket.main.id
  acl        = "private"
}

# ===================================
# LOGGING - Enable Server Access Logging
# ===================================
resource "aws_s3_bucket_logging" "main" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "main-bucket-logs/"

  depends_on = [aws_s3_bucket_acl.logs]
}

# ===================================
# BUCKET POLICY - Add Bucket Policy
# ===================================
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ===================================
# LIFECYCLE POLICY - Create Lifecycle Rules
# ===================================
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.main.id

  # Rule 1: Transition objects to different storage classes
  rule {
    id     = "transition-to-cheaper-storage"
    status = "Enabled"

    filter {
      prefix = "documents/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  # Rule 2: Expire old versions
  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }

  # Rule 3: Delete temporary files
  rule {
    id     = "delete-temp-files"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 7
    }
  }

  # Rule 4: Clean up expired delete markers
  rule {
    id     = "cleanup-delete-markers"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }
  }

  # Rule 5: Abort incomplete multipart uploads
  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

# ===================================
# NOTIFICATIONS - SNS Topic for Events
# ===================================
resource "aws_sns_topic" "bucket_notifications" {
  count = var.enable_notifications ? 1 : 0
  name  = "${var.main_bucket_name}-notifications"

  tags = var.common_tags
}

resource "aws_sns_topic_policy" "bucket_notifications" {
  count = var.enable_notifications ? 1 : 0
  arn   = aws_sns_topic.bucket_notifications[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.bucket_notifications[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.main.arn
          }
        }
      }
    ]
  })
}

# NOTIFICATIONS - SQS Queue for Events
resource "aws_sqs_queue" "bucket_notifications" {
  count = var.enable_notifications ? 1 : 0
  name  = "${var.main_bucket_name}-notifications"

  tags = var.common_tags
}

resource "aws_sqs_queue_policy" "bucket_notifications" {
  count     = var.enable_notifications ? 1 : 0
  queue_url = aws_sqs_queue.bucket_notifications[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.bucket_notifications[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.main.arn
          }
        }
      }
    ]
  })
}

# NOTIFICATIONS - Configure S3 Event Notifications
resource "aws_s3_bucket_notification" "main" {
  count  = var.enable_notifications ? 1 : 0
  bucket = aws_s3_bucket.main.id

  topic {
    topic_arn = aws_sns_topic.bucket_notifications[0].arn
    events    = ["s3:ObjectCreated:*"]
  }

  queue {
    queue_arn = aws_sqs_queue.bucket_notifications[0].arn
    events    = ["s3:ObjectRemoved:*"]
  }

  depends_on = [
    aws_sns_topic_policy.bucket_notifications,
    aws_sqs_queue_policy.bucket_notifications
  ]
}

# ===================================
# REPLICATION - IAM Role for Cross-Region Replication
# ===================================
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${var.main_bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  role  = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner",
        ]
        Resource = [
          "${aws_s3_bucket.cross_account[0].arn}/*",
          "${aws_s3_bucket.cross_region[0].arn}/*"
        ]
      }
    ]
  })
}

# REPLICATION - Destination Bucket for Cross-Account (in different account, same region us-east-1)
resource "aws_s3_bucket" "cross_account" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.destination_account
  bucket   = var.replication_bucket_name

  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.replication_bucket_name
      Type = "CrossAccountReplication"
    }
  )
}

# Cross-Account Bucket - Versioning (required for replication)
resource "aws_s3_bucket_versioning" "cross_account" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.destination_account
  bucket   = aws_s3_bucket.cross_account[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cross-Account Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cross_account" {
  count    = var.enable_replication && var.enable_encryption ? 1 : 0
  provider = aws.destination_account
  bucket   = aws_s3_bucket.cross_account[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Cross-Account Bucket - Policy to allow cross-account replication
resource "aws_s3_bucket_policy" "cross_account" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.destination_account
  bucket   = aws_s3_bucket.cross_account[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountReplication"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication[0].arn
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.cross_account[0].arn}/*"
      },
      {
        Sid    = "AllowCrossAccountReplicationList"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication[0].arn
        }
        Action = [
          "s3:List*",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = aws_s3_bucket.cross_account[0].arn
      }
    ]
  })
}

# ===================================
# CROSS-REGION REPLICATION BUCKET (same account, different region us-west-1)
# ===================================
resource "aws_s3_bucket" "cross_region" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.cross_region
  bucket   = var.cross_region_bucket_name

  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.cross_region_bucket_name
      Type = "CrossRegionReplication"
    }
  )
}

# Cross-Region Bucket - Versioning (required for replication)
resource "aws_s3_bucket_versioning" "cross_region" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.cross_region
  bucket   = aws_s3_bucket.cross_region[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cross-Region Bucket - Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cross_region" {
  count    = var.enable_replication && var.enable_encryption ? 1 : 0
  provider = aws.cross_region
  bucket   = aws_s3_bucket.cross_region[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# REPLICATION - Configure Cross-Account and Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "main" {
  count  = var.enable_replication ? 1 : 0
  bucket = aws_s3_bucket.main.id
  role   = aws_iam_role.replication[0].arn

  # Rule 1: Cross-Account Replication (to different account, same region)
  rule {
    id       = "cross-account-replication"
    status   = "Enabled"
    priority = 1

    filter {
      prefix = "cross-account/"
    }

    destination {
      bucket        = aws_s3_bucket.cross_account[0].arn
      storage_class = "STANDARD"
      
      account = var.destination_account_id
      
      access_control_translation {
        owner = "Destination"
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  # Rule 2: Cross-Region Replication (to same account, different region)
  rule {
    id       = "cross-region-replication"
    status   = "Enabled"
    priority = 2

    filter {
      prefix = "cross-region/"
    }

    destination {
      bucket        = aws_s3_bucket.cross_region[0].arn
      storage_class = "STANDARD_IA"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  # Rule 3: Replicate everything else to cross-region
  rule {
    id       = "replicate-all-to-cross-region"
    status   = "Enabled"
    priority = 3

    filter {}

    destination {
      bucket        = aws_s3_bucket.cross_region[0].arn
      storage_class = "STANDARD_IA"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.main,
    aws_s3_bucket_versioning.cross_account,
    aws_s3_bucket_versioning.cross_region,
    aws_iam_role_policy.replication
  ]
}

# ===================================
# TRANSFER ACCELERATION
# ===================================
resource "aws_s3_bucket_accelerate_configuration" "main" {
  count  = var.enable_transfer_acceleration ? 1 : 0
  bucket = aws_s3_bucket.main.id
  status = "Enabled"
}

# ===================================
# STORAGE CLASS ANALYSIS
# ===================================
resource "aws_s3_bucket_analytics_configuration" "main_documents" {
  count  = var.enable_analytics ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "documents-analytics"

  filter {
    prefix = "documents/"
  }

  storage_class_analysis {
    data_export {
      output_schema_version = "V_1"
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.analytics.arn
          prefix     = "analytics/documents/"
        }
      }
    }
  }
}

resource "aws_s3_bucket_analytics_configuration" "main_logs" {
  count  = var.enable_analytics ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "logs-analytics"

  filter {
    prefix = "logs/"
  }

  storage_class_analysis {
    data_export {
      output_schema_version = "V_1"
      destination {
        s3_bucket_destination {
          bucket_arn = aws_s3_bucket.analytics.arn
          prefix     = "analytics/logs/"
        }
      }
    }
  }
}

# ===================================
# INVENTORY CONFIGURATION
# ===================================
resource "aws_s3_bucket_inventory" "main_weekly" {
  count                    = var.enable_inventory ? 1 : 0
  bucket                   = aws_s3_bucket.main.id
  name                     = "weekly-inventory"
  included_object_versions = "All"
  enabled                  = true

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      bucket_arn = aws_s3_bucket.analytics.arn
      prefix     = "inventory/"
      format     = "CSV"
    }
  }

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "IntelligentTieringAccessTier"
  ]
}

# ===================================
# INTELLIGENT TIERING
# ===================================
resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  name   = "entire-bucket-tiering"
  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# ===================================
# BUCKET METRICS
# ===================================
resource "aws_s3_bucket_metric" "main_all" {
  bucket = aws_s3_bucket.main.id
  name   = "all-objects"
}

resource "aws_s3_bucket_metric" "main_documents" {
  bucket = aws_s3_bucket.main.id
  name   = "documents-metrics"

  filter {
    prefix = "documents/"
  }
}

# ===================================
# CORS CONFIGURATION
# ===================================
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ===================================
# REQUEST PAYMENT
# ===================================
resource "aws_s3_bucket_request_payment_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  payer  = "BucketOwner"
}

# ===================================
# STATIC WEBSITE HOSTING BUCKET
# ===================================
resource "aws_s3_bucket" "website" {
  count         = var.enable_website ? 1 : 0
  bucket        = var.website_bucket_name
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = var.website_bucket_name
      Type = "Website"
    }
  )
}

# Website Bucket - Website Configuration
resource "aws_s3_bucket_website_configuration" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}

# Website Bucket - Public Access (allowed for website)
resource "aws_s3_bucket_public_access_block" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Website Bucket - Ownership Controls
resource "aws_s3_bucket_ownership_controls" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Website Bucket - Public Read ACL
resource "aws_s3_bucket_acl" "website" {
  count      = var.enable_website ? 1 : 0
  depends_on = [aws_s3_bucket_ownership_controls.website, aws_s3_bucket_public_access_block.website]
  bucket     = aws_s3_bucket.website[0].id
  acl        = "public-read"
}

# Website Bucket - Bucket Policy for Public Read
resource "aws_s3_bucket_policy" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website[0].arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Website Bucket - CORS for web access
resource "aws_s3_bucket_cors_configuration" "website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.website[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# ===================================
# BUCKET TAGS (demonstrating tagging)
# ===================================
resource "aws_s3_bucket" "tagged_example" {
  bucket        = "${var.main_bucket_name}-tagged"
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.main_bucket_name}-tagged"
      Type        = "Tagged Example"
      Department  = "IT"
      CostCenter  = "Engineering"
      Compliance  = "Required"
      DataClass   = "Sensitive"
      BackupDaily = "true"
    }
  )
}

# ===================================
# OUTPUTS
# ===================================
# Main Bucket Outputs
output "main_bucket_id" {
  description = "The name of the main bucket"
  value       = aws_s3_bucket.main.id
}

output "main_bucket_arn" {
  description = "The ARN of the main bucket"
  value       = aws_s3_bucket.main.arn
}

output "main_bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "main_bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

# Logs Bucket Output
output "logs_bucket_id" {
  description = "The name of the logs bucket"
  value       = aws_s3_bucket.logs.id
}

# Replication Bucket Outputs
output "cross_account_bucket_id" {
  description = "The name of the cross-account replication bucket"
  value       = var.enable_replication ? aws_s3_bucket.cross_account[0].id : null
}

output "cross_region_bucket_id" {
  description = "The name of the cross-region replication bucket"
  value       = var.enable_replication ? aws_s3_bucket.cross_region[0].id : null
}

# Website Bucket Outputs
output "website_bucket_id" {
  description = "The name of the website bucket"
  value       = var.enable_website ? aws_s3_bucket.website[0].id : null
}

output "website_endpoint" {
  description = "The website endpoint URL"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.website[0].website_endpoint : null
}

output "website_url" {
  description = "Full website URL"
  value       = var.enable_website ? "http://${aws_s3_bucket_website_configuration.website[0].website_endpoint}" : null
}

# Analytics Bucket Output
output "analytics_bucket_id" {
  description = "The name of the analytics bucket"
  value       = aws_s3_bucket.analytics.id
}

# SNS Topic Output
output "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  value       = var.enable_notifications ? aws_sns_topic.bucket_notifications[0].arn : null
}

# SQS Queue Output
output "sqs_queue_url" {
  description = "SQS queue URL for notifications"
  value       = var.enable_notifications ? aws_sqs_queue.bucket_notifications[0].url : null
}

# Transfer Acceleration Endpoint
output "accelerated_endpoint" {
  description = "Transfer acceleration endpoint"
  value       = var.enable_transfer_acceleration ? "${var.main_bucket_name}.s3-accelerate.amazonaws.com" : null
}

# Feature Status
output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.enable_versioning
}

output "encryption_enabled" {
  description = "Whether encryption is enabled"
  value       = var.enable_encryption
}

output "logging_enabled" {
  description = "Whether logging is enabled"
  value       = var.enable_logging
}

output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = var.enable_replication
}

output "acceleration_enabled" {
  description = "Whether transfer acceleration is enabled"
  value       = var.enable_transfer_acceleration
}

output "summary" {
  description = "Summary of all created resources"
  value = {
    main_bucket              = aws_s3_bucket.main.id
    logs_bucket              = aws_s3_bucket.logs.id
    analytics_bucket         = aws_s3_bucket.analytics.id
    cross_account_bucket     = var.enable_replication ? aws_s3_bucket.cross_account[0].id : "disabled"
    cross_account_region     = var.enable_replication ? var.replication_region : "disabled"
    cross_region_bucket      = var.enable_replication ? aws_s3_bucket.cross_region[0].id : "disabled"
    cross_region_region      = var.enable_replication ? var.cross_region : "disabled"
    website_bucket           = var.enable_website ? aws_s3_bucket.website[0].id : "disabled"
    website_url              = var.enable_website ? "http://${aws_s3_bucket_website_configuration.website[0].website_endpoint}" : "disabled"
    versioning               = var.enable_versioning ? "enabled" : "suspended"
    encryption               = var.enable_encryption ? "enabled" : "disabled"
    logging                  = var.enable_logging ? "enabled" : "disabled"
    cross_account_replication = var.enable_replication ? "enabled" : "disabled"
    cross_region_replication = var.enable_replication ? "enabled" : "disabled"
    notifications            = var.enable_notifications ? "enabled" : "disabled"
    transfer_accel           = var.enable_transfer_acceleration ? "enabled" : "disabled"
    lifecycle_policies       = var.enable_lifecycle ? "enabled" : "disabled"
    analytics                = var.enable_analytics ? "enabled" : "disabled"
    inventory                = var.enable_inventory ? "enabled" : "disabled"
  }
}


# Cross-Account Bucket - Ownership Controls (REQUIRED for cross-account replication)
resource "aws_s3_bucket_ownership_controls" "cross_account" {
  count    = var.enable_replication ? 1 : 0
  provider = aws.destination_account
  bucket   = aws_s3_bucket.cross_account[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
