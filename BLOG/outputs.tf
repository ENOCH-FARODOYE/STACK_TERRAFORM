# ========================================
# Terraform Outputs
# ========================================

# Application Load Balancer
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

# WordPress URL
output "wordpress_url" {
  description = "WordPress blog URL"
  value       = "http://${var.route53_config.record_name}"
}

# RDS Database
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.wordpress.endpoint
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = var.database_config.db_name
}

# EFS File System
output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.wordpress.id
}

# EC2 Key Pair
output "key_pair_name" {
  description = "EC2 key pair name"
  value       = aws_key_pair.ec2.key_name
}

# Auto Scaling Group
output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.wordpress.name
}

# Launch Template
output "launch_template_id" {
  description = "Launch template ID"
  value       = aws_launch_template.wordpress.id
}

# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Subnets
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}
