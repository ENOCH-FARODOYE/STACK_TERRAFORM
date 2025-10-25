

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "redirect-bucket-enoch-v19"
}

variable "AWS_REGION" {}

variable "enable_website_redirect" {
  default = true
}

variable "redirect_target_host" {
  default = "www.example.com"
}

variable "redirect_protocol" {
  default = "https"
}

variable "redirect_http_code" {
  default = "301"
}
