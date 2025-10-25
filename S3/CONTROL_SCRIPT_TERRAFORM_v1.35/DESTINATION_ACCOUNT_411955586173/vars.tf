variable "AWS_ACCESS_KEY" {
  description = "Destination account access key"
}

variable "AWS_SECRET_KEY" {
  description = "Destination account secret key"
  sensitive   = true
}

variable "AWS_REGION" {
  description = "Region for destination bucket"
  default     = "us-east-1"
}

variable "destination_bucket_name" {
  description = "Name of the destination replication bucket"
  default     = "replica-bucket-enoch-v125-sameregion"
}

variable "source_account_id" {
  description = "Source AWS account ID"
  default     = "978820380225"
}

variable "source_replication_role_name" {
  description = "Name of replication role in source account"
  default     = "s3-replication-role-enoch-v125-sameregion-crossaccount"
}
