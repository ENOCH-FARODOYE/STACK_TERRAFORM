##############################################################################
# Map-Based Variables for Multi-Environment Deployment
##############################################################################

# ========================================
# Environment Configuration Map
# ========================================
variable "environment" {
  description = "Environment name (dev, automation, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "automation", "prod"], var.environment)
    error_message = "Environment must be dev, automation, or prod."
  }
}

variable "environment_config" {
  description = "Environment-specific configuration"
  type = object({
    aws_region             = string
    management_account_id  = string
    dev_account_id         = string
    project_name           = string
    engineering_role_name  = string
  })
}

# ========================================
# Network Configuration Map
# ========================================
variable "network_config" {
  description = "Network configuration for VPC and subnets"
  type = object({
    vpc_cidr                       = string
    public_subnet_1_cidr           = string
    public_subnet_2_cidr           = string
    private_app_subnet_1_cidr      = string
    private_app_subnet_2_cidr      = string
    private_mysql_subnet_1_cidr    = string
    private_mysql_subnet_2_cidr    = string
    private_oracle_subnet_1_cidr   = string
    private_oracle_subnet_2_cidr   = string
    private_java_db_subnet_1_cidr  = string
    private_java_db_subnet_2_cidr  = string
    private_java_app_subnet_1_cidr = string
    private_java_app_subnet_2_cidr = string
  })
}

# ========================================
# Compute Configuration Map (EC2/ASG Properties)
# ========================================
variable "compute_config" {
  description = "EC2 and Auto Scaling configuration"
  type = object({
    instance_type             = string
    key_name_prefix           = string
    asg_min_size              = number
    asg_max_size              = number
    asg_desired_capacity      = number
    health_check_grace_period = number
    default_cooldown          = number
    cpu_target_value          = number
    alb_request_target_value  = number
    enable_detailed_monitoring = bool
  })
}

# ========================================
# Database Configuration Map (RDS Properties)
# ========================================
variable "database_config" {
  description = "RDS database configuration"
  type = object({
    identifier                 = string
    snapshot_identifier        = string
    instance_class             = string
    engine                     = string
    storage_type               = string
    storage_encrypted          = bool
    multi_az                   = bool
    backup_retention_period    = number
    backup_window              = string
    maintenance_window         = string
    deletion_protection        = bool
    skip_final_snapshot        = bool
    enable_cloudwatch_logs     = list(string)
    db_name                    = string
    db_username                = string
  })
}

# ========================================
# Security Group Rules Map
# ========================================
variable "security_group_rules" {
  description = "Security group rules configuration"
  type = object({
    alb_ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    
    ec2_ingress_rules = list(object({
      description     = string
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = optional(list(string))
      source_sg_type  = optional(string) # "alb" or null
    }))
    
    rds_ingress_rules = list(object({
      description    = string
      from_port      = number
      to_port        = number
      protocol       = string
      source_sg_type = string # "ec2"
    }))
    
    efs_ingress_rules = list(object({
      description    = string
      from_port      = number
      to_port        = number
      protocol       = string
      source_sg_type = string # "ec2"
    }))
  })
}

# ========================================
# ALB Configuration Map
# ========================================
variable "alb_config" {
  description = "Application Load Balancer configuration"
  type = object({
    internal                     = bool
    enable_deletion_protection   = bool
    enable_http2                 = bool
    enable_cross_zone_lb         = bool
    target_group_port            = number
    target_group_protocol        = string
    health_check_path            = string
    health_check_healthy_threshold   = number
    health_check_unhealthy_threshold = number
    health_check_timeout         = number
    health_check_interval        = number
    health_check_matcher         = string
    deregistration_delay         = number
    stickiness_enabled           = bool
    stickiness_duration          = number
  })
}

# ========================================
# EFS Configuration Map
# ========================================
variable "efs_config" {
  description = "EFS configuration"
  type = object({
    creation_token       = string
    encrypted            = bool
    performance_mode     = string
    throughput_mode      = string
    transition_to_ia_days = string
  })
}

# ========================================
# Route53 Configuration Map
# ========================================
variable "route53_config" {
  description = "Route53 DNS configuration"
  type = object({
    hosted_zone_name       = string
    record_name            = string
    evaluate_target_health = bool
  })
}

# ========================================
# IAM Configuration Map
# ========================================
variable "iam_config" {
  description = "IAM roles and policies configuration"
  type = object({
    ssm_role_name               = string
    ec2_role_name_suffix        = string
    external_id                 = string
    ssm_parameter_path_prefix   = string
  })
}



# ========================================
# Common Tags
# ========================================
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
