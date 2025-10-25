variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "advanced-bucket-enoch-v125"
}

variable "destination_bucket_name" {
  default = "advanced-bucket-enoch-v125-replica"
}

variable "cross_account_destination_bucket" {
  default = "replica-bucket-enoch-v125-crossaccount"
}

variable "sameregion_crossaccount_destination_bucket" {
  default = "replica-bucket-enoch-v125-sameregion"
}

variable "destination_account_id" {
  default = "411955586173"
}

variable "AWS_REGION" {}

variable "DESTINATION_REGION" {
  default = "us-west-2"
}

variable "enable_versioning" {
  description = "Enable versioning (required for CRR)"
  type        = bool
  default     = true
}

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration"
  type        = bool
  default     = false
}
