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
