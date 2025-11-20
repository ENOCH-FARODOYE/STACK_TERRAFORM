# ========================================
# General Variables
# ========================================
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile for Management Account"
  type        = string
}

variable "management_account_id" {
  description = "Management Account ID"
  type        = string
}

variable "dev_account_id" {
  description = "Dev Account ID"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "enoch-blog"
}

# ========================================
# Network Variables
# ========================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_1" {
  description = "First availability zone"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Second availability zone"
  type        = string
  default     = "us-east-1b"
}

variable "subnet_1_cidr" {
  description = "CIDR block for subnet 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_2_cidr" {
  description = "CIDR block for subnet 2"
  type        = string
  default     = "10.0.2.0/24"
}
