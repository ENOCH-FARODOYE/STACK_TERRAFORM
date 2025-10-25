

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch"
}

variable "AWS_REGION" {}

variable "force_destroy" {
  description = "Flag to determine whether to forcefully delete all bucket objects when deleting"
  type        = bool
  default     = false
}

