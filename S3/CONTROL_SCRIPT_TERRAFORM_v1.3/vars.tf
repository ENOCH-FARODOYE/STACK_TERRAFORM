


variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "data-storage-enoch-v13"
}

variable "AWS_REGION" {}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "Enoch"
    Project     = "S3-Bucket-Automation"
    CostCenter  = "Engineering"
  }
}
