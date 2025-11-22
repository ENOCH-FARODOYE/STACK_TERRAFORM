# ========================================
# Update SSM Parameter in Management Account
# ========================================

resource "null_resource" "update_efs_ssm" {
  depends_on = [aws_efs_file_system.main]

  provisioner "local-exec" {
    command = <<-EOT
      aws sts assume-role \
        --role-arn ${var.management_role_arn} \
        --role-session-name "terraform-efs-update" \
        --external-id "clixx-ssm-access" \
        --region ${var.aws_region} \
        --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
        --output text | \
      while read access_key secret_key session_token; do
        AWS_ACCESS_KEY_ID=$access_key \
        AWS_SECRET_ACCESS_KEY=$secret_key \
        AWS_SESSION_TOKEN=$session_token \
        aws ssm put-parameter \
          --name "/clixx/efs/id" \
          --value "${aws_efs_file_system.main.id}" \
          --overwrite \
          --region ${var.aws_region}
      done
    EOT
  }

  triggers = {
    efs_id = aws_efs_file_system.main.id
  }
}
