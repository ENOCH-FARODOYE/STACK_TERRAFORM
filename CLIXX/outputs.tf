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
  value       = aws_subnet.subnet_1.id
}

output "subnet_2_id" {
  description = "Subnet 2 ID"
  value       = aws_subnet.subnet_2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "route_table_id" {
  description = "Route Table ID"
  value       = aws_route_table.main.id
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
