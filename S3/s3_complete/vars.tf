# ===================================
# AWS Credentials - Source Account
# ===================================
variable "AWS_ACCESS_KEY" {
  description = "AWS Access Key for source account"
  type        = string
  sensitive   = true
}

variable "AWS_SECRET_KEY" {
  description = "AWS Secret Key for source account"
  type        = string
  sensitive   = true
}

variable "AWS_REGION" {
  description = "AWS Region for source account"
  type        = string
  default     = "us-east-1"
}

# ===================================
# AWS Credentials - Destination Account
# ===================================
variable "DEST_AWS_ACCESS_KEY" {
  description = "AWS Access Key for destination account"
  type        = string
  sensitive   = true
}

variable "DEST_AWS_SECRET_KEY" {
  description = "AWS Secret Key for destination account"
  type        = string
  sensitive   = true
}

# ===================================
# Account IDs
# ===================================
variable "source_account_id" {
  description = "Source AWS Account ID"
  type        = string
  default     = "978820380225"
}

variable "destination_account_id" {
  description = "Destination AWS Account ID for cross-account replication"
  type        = string
  default     = "411955586173"
}

# ===================================
# Main Bucket Configuration
# ===================================
variable "main_bucket_name" {
  description = "Name of the main S3 bucket"
  type        = string
  default     = "data-storage-enoch-main"
}

# ===================================
# Logs Bucket Configuration
# ===================================
variable "logs_bucket_name" {
  description = "Name of the logs bucket for server access logs"
  type        = string
  default     = "data-storage-enoch-logs"
}

# ===================================
# Replication Bucket Configuration
# ===================================
variable "replication_bucket_name" {
  description = "Name of the cross-account replication destination bucket"
  type        = string
  default     = "data-storage-enoch-replica"
}

variable "replication_region" {
  description = "AWS Region for cross-account replication bucket (same source account, different account)"
  type        = string
  default     = "us-east-1"
}

# ===================================
# Cross-Region Bucket Configuration
# ===================================
variable "cross_region_bucket_name" {
  description = "Name of the cross-region replication bucket (same account)"
  type        = string
  default     = "data-storage-enoch-cross-region"
}

variable "cross_region" {
  description = "AWS Region for cross-region replication (same account, different region)"
  type        = string
  default     = "us-west-1"
}

# ===================================
# Website Bucket Configuration
# ===================================
variable "website_bucket_name" {
  description = "Name of the static website bucket"
  type        = string
  default     = "data-storage-enoch-website"
}

# ===================================
# Analytics Bucket Configuration
# ===================================
variable "analytics_bucket_name" {
  description = "Name of the analytics destination bucket"
  type        = string
  default     = "data-storage-enoch-analytics"
}

# ===================================
# Feature Toggles
# ===================================
variable "enable_versioning" {
  description = "Enable versioning on main bucket"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption on buckets"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable server access logging"
  type        = bool
  default     = true
}

variable "enable_website" {
  description = "Enable static website hosting"
  type        = bool
  default     = true
}

variable "enable_replication" {
  description = "Enable cross-region and cross-account replication"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Enable lifecycle policies"
  type        = bool
  default     = true
}

variable "enable_notifications" {
  description = "Enable event notifications"
  type        = bool
  default     = true
}

variable "enable_transfer_acceleration" {
  description = "Enable transfer acceleration"
  type        = bool
  default     = true
}

variable "enable_analytics" {
  description = "Enable storage class analytics"
  type        = bool
  default     = true
}

variable "enable_inventory" {
  description = "Enable inventory reports"
  type        = bool
  default     = true
}

# ===================================
# Tags
# ===================================
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "S3-Complete-Demo"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Enoch"
  }
}
