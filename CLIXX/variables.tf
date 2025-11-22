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
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "clixx"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_1_cidr" {
  description = "Subnet 1 CIDR block"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_2_cidr" {
  description = "Subnet 2 CIDR block"
  type        = string
  default     = "10.1.2.0/24"
}

variable "availability_zone_1" {
  description = "Availability zone 1"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Availability zone 2"
  type        = string
  default     = "us-east-1b"
}
