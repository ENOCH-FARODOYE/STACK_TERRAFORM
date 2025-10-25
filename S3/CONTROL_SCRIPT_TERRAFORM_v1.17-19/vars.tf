

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "versioned-bucket-enoch-v117"
}

variable "AWS_REGION" {}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = true
}
