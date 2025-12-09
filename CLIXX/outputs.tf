##############################################################################
# Outputs
##############################################################################

output "ssm_parameter_arns" {
  description = "ARNs of all SSM parameters"
  value = {
    efs_id       = aws_ssm_parameter.efs_id.arn
    rds_endpoint = aws_ssm_parameter.rds_endpoint.arn
    db_name      = aws_ssm_parameter.db_name.arn
    db_username  = aws_ssm_parameter.db_username.arn
    db_password  = aws_ssm_parameter.db_password.arn
  }
  sensitive = true
}

output "iam_role_arn" {
  description = "ARN of SSM Parameter Access Role"
  value       = aws_iam_role.ssm_parameter_access.arn
}

output "iam_role_name" {
  description = "Name of SSM Parameter Access Role"
  value       = aws_iam_role.ssm_parameter_access.name
}

output "management_account_id" {
  description = "Management Account ID"
  value       = data.aws_caller_identity.current.account_id
}

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_1_id" {
  description = "Subnet 1 ID"
  value       = aws_subnet.public_1.id
}

output "subnet_2_id" {
  description = "Subnet 2 ID"
  value       = aws_subnet.public_2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "Route Table ID"
  value       = aws_route_table.public.id
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2 Security Group ID"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "efs_security_group_id" {
  description = "EFS Security Group ID"
  value       = aws_security_group.efs.id
}
# EFS Outputs
output "efs_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.main.id
}

output "efs_dns_name" {
  description = "EFS DNS Name"
  value       = aws_efs_file_system.main.dns_name
}
# RDS Outputs
output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.main.endpoint
}

output "rds_instance_id" {
  description = "RDS Instance ID"
  value       = aws_db_instance.main.id
}

output "rds_address" {
  description = "RDS Address (without port)"
  value       = aws_db_instance.main.address
}
# ALB Outputs
output "alb_id" {
  description = "ALB ID"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Hosted Zone ID"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.main.arn
}

output "target_group_name" {
  description = "Target Group Name"
  value       = aws_lb_target_group.main.name
}
# Route 53 Outputs
output "route53_fqdn" {
  description = "Fully Qualified Domain Name"
  value       = aws_route53_record.clixx_dev.fqdn
}

output "route53_name" {
  description = "Route 53 Record Name"
  value       = aws_route53_record.clixx_dev.name
}

output "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

# EC2 IAM Outputs
output "ec2_iam_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2_instance.arn
}

output "ec2_iam_role_name" {
  description = "EC2 IAM Role Name"
  value       = aws_iam_role.ec2_instance.name
}

output "ec2_instance_profile_arn" {
  description = "EC2 Instance Profile ARN"
  value       = aws_iam_instance_profile.ec2.arn
}

output "ec2_instance_profile_name" {
  description = "EC2 Instance Profile Name"
  value       = aws_iam_instance_profile.ec2.name
}
# Key Pair Outputs
output "key_pair_name" {
  description = "EC2 Key Pair Name"
  value       = aws_key_pair.main.key_name
}

output "key_pair_id" {
  description = "EC2 Key Pair ID"
  value       = aws_key_pair.main.id
}

output "private_key_pem" {
  description = "Private key PEM (save this securely!)"
  value       = tls_private_key.main.private_key_pem
  sensitive   = true
}
# Launch Template Outputs
output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.main.id
}

output "launch_template_latest_version" {
  description = "Launch Template Latest Version"
  value       = aws_launch_template.main.latest_version
}

output "launch_template_name" {
  description = "Launch Template Name"
  value       = aws_launch_template.main.name
}
# Auto Scaling Group Outputs
output "asg_id" {
  description = "Auto Scaling Group ID"
  value       = aws_autoscaling_group.main.id
}

output "asg_name" {
  description = "Auto Scaling Group Name"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.main.arn
}

output "asg_min_size" {
  description = "Auto Scaling Group Min Size"
  value       = aws_autoscaling_group.main.min_size
}

output "asg_max_size" {
  description = "Auto Scaling Group Max Size"
  value       = aws_autoscaling_group.main.max_size
}

output "asg_desired_capacity" {
  description = "Auto Scaling Group Desired Capacity"
  value       = aws_autoscaling_group.main.desired_capacity
}
