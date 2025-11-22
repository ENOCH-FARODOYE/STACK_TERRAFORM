variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dev_account_id" {
  description = "Dev account ID"
  type        = string
}

variable "engineering_role_name" {
  description = "Engineering role name in Dev account"
  type        = string
  default     = "Engineer"
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
variable "management_account_id" {
  description = "Management Account ID"
  type        = string
  default     = "978820380225"
}

variable "management_role_arn" {
  description = "Management Account SSM Role ARN"
  type        = string
  default     = "arn:aws:iam::978820380225:role/SSMParameterAccessRole"
}
