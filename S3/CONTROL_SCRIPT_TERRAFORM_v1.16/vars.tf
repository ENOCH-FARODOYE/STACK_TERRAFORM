

variable "AWS_ACCESS_KEY" {}

variable "AWS_SECRET_KEY" {}

variable "bucket_name" {
  default = "object-lock-bucket-enoch-v116"
}

variable "AWS_REGION" {}

variable "enable_object_lock" {
  description = "Enable object lock for the bucket"
  type        = bool
  default     = true
}

variable "object_lock_mode" {
  description = "Object lock mode: GOVERNANCE or COMPLIANCE"
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "Object lock mode must be either GOVERNANCE or COMPLIANCE."
  }
}

variable "retention_days" {
  description = "Default retention period in days"
  type        = number
  default     = 30
}
