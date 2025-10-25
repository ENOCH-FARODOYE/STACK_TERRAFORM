

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch"
}

variable "AWS_REGION" {
  default = "us-east-1"
}

variable "versioning_enabled" {
  description = "Enable or suspend versioning on the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_enabled" {
  description = "Enable default encryption on the S3 bucket"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "SSE-S3 or SSE-KMS"
  type        = string
  default     = "SSE-S3"
}

variable "kms_key_id" {
  description = "KMS key ID for SSE-KMS encryption"
  type        = string
  default     = ""   # leave empty for SSE-S3
}

