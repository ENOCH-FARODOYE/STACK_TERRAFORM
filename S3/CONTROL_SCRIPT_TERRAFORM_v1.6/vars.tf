


variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch-v16"
}

variable "log_bucket_name" {
  default = "logs-storage-enoch-v16"
}

variable "AWS_REGION" {}

variable "enable_server_logging" {
  default = true
}

variable "log_prefix" {
  default = "logs/access/"
}
