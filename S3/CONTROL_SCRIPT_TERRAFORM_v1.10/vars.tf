

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "notifications-bucket-enoch-v110"
}

variable "sqs_queue_name" {
  default = "s3-notifications-queue-v110"
}

variable "AWS_REGION" {}

variable "enable_event_notifications" {
  default = true
}

variable "notification_events" {
  type    = list(string)
  default = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
}

variable "filter_prefix" {
  default = ""
}

variable "filter_suffix" {
  default = ""
}
