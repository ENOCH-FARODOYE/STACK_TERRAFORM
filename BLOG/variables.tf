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

# ========================================
# Database Variables
# ========================================
variable "db_snapshot_identifier" {
  description = "RDS snapshot to restore from"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_identifier" {
  description = "Database identifier"
  type        = string
  default     = "enoch-blog-db"
}

# ========================================
# Database Credentials Variables
# ========================================
variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "enoch_wordpress_db"
}

# ========================================
# Route53 Variables
# ========================================
variable "domain_name" {
  description = "Domain name for the blog"
  type        = string
  default     = "enoch-stack.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

# ========================================
# EC2 Instance Variables
# ========================================
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
