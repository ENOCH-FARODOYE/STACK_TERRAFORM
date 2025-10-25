

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "website-storage-enoch-v18"
}

variable "AWS_REGION" {}

variable "enable_static_website" {
  default = true
}

variable "index_document" {
  default = "index.html"
}

variable "error_document" {
  default = "error.html"
}
