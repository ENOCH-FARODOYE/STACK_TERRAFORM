

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch"
}

variable "AWS_REGION" {}

variable "versioning_enabled" {
  description = "Enable or suspend versioning on the S3 bucket"
  type        = bool
  default     = true
}

