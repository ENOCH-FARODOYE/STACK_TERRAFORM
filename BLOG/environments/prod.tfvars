##############################################################################
# Production Environment Configuration
##############################################################################

environment = "prod"

# ========================================
# Environment Settings
# ========================================
environment_config = {
  aws_region            = "us-east-1"
  management_account_id = "978820380225"
  dev_account_id        = "411955586173"
  project_name          = "enoch-blog"
  engineering_role_name = "Engineer"
}

# ========================================
# Network Configuration
# ========================================
network_config = {
  vpc_cidr              = "10.2.0.0/16"
  public_subnet_1_cidr  = "10.2.1.0/24"
  public_subnet_2_cidr  = "10.2.2.0/24"
  private_subnet_1_cidr = "10.2.10.0/24"
  private_subnet_2_cidr = "10.2.11.0/24"
}

# ========================================
# Compute Configuration (EC2/ASG)
# ========================================
compute_config = {
  instance_type              = "t3.medium"
  key_name_prefix            = "enoch-blog"
  asg_min_size               = 3
  asg_max_size               = 10
  asg_desired_capacity       = 3
  health_check_grace_period  = 480
  default_cooldown           = 180
  cpu_target_value           = 70.0
  alb_request_target_value   = 1000.0
  enable_detailed_monitoring = true
}

# ========================================
# Database Configuration (RDS)
# ========================================
database_config = {
  identifier              = "enoch-blog-prod-db"
  snapshot_identifier     = "enoch-blog-snapshot-final"
  instance_class          = "db.t3.medium"
  engine                  = "mysql"
  engine_version          = "8.4"
  storage_type            = "gp3"
  storage_encrypted       = true
  backup_retention_period = 30
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  skip_final_snapshot     = false
  enable_cloudwatch_logs  = ["error", "general", "slowquery"]
  db_name                 = "enoch_wordpress_db"
  db_username             = "admin"
  db_password             = "Pamilerin1996"
}

# ========================================
# Security Group Rules
# ========================================
security_group_rules = {
  alb_ingress_rules = [
    {
      description = "HTTP from internet"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS from internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  ec2_ingress_rules = [
    {
      description    = "HTTP from ALB"
      from_port      = 80
      to_port        = 80
      protocol       = "tcp"
      source_sg_type = "alb"
    }
    # Note: SSH removed for production security
  ]

  rds_ingress_rules = [
    {
      description    = "MySQL from EC2"
      from_port      = 3306
      to_port        = 3306
      protocol       = "tcp"
      source_sg_type = "ec2"
    }
  ]

  efs_ingress_rules = [
    {
      description    = "NFS from EC2"
      from_port      = 2049
      to_port        = 2049
      protocol       = "tcp"
      source_sg_type = "ec2"
    }
  ]
}

# ========================================
# ALB Configuration
# ========================================
alb_config = {
  internal                         = false
  enable_deletion_protection       = true
  enable_http2                     = true
  enable_cross_zone_lb             = true
  target_group_port                = 80
  target_group_protocol            = "HTTP"
  health_check_path                = "/health.html"
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 5
  health_check_timeout             = 15
  health_check_interval            = 30
  health_check_matcher             = "200"
  deregistration_delay             = 30
  stickiness_enabled               = true
  stickiness_duration              = 86400
}

# ========================================
# EFS Configuration
# ========================================
efs_config = {
  creation_token        = "enoch-blog-prod-efs"
  encrypted             = true
  performance_mode      = "generalPurpose"
  throughput_mode       = "bursting"
  transition_to_ia_days = "AFTER_30_DAYS"
}

# ========================================
# Route53 Configuration
# ========================================
route53_config = {
  hosted_zone_name       = "enoch-stack.com"
  hosted_zone_id         = "Z09754283M1E3YFVQVDL2"
  record_name            = "blog.enoch-stack.com"
  evaluate_target_health = true
}

# ========================================
# IAM Configuration
# ========================================
iam_config = {
  ssm_role_name             = "SSMParameterAccessRole"
  ec2_role_name_suffix      = "ec2-role"
  ssm_parameter_path_prefix = "/enoch-blog"
}

# ========================================
# Common Tags
# ========================================
common_tags = {
  Environment = "prod"
  Project     = "EnochBlog"
  ManagedBy   = "Terraform"
  Owner       = "Pamilerin"
  CostCenter  = "Engineering"
}

aws_profile = "stack_admin_enoch"
