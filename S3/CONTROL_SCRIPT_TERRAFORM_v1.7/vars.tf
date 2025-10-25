

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch-v17"
}

variable "cloudtrail_bucket_name" {
  default = "cloudtrail-logs-enoch-v17"
}

variable "cloudtrail_name" {
  default = "s3-object-level-trail-v17"
}

variable "AWS_REGION" {}

variable "enable_cloudtrail" {
  default = true
}
