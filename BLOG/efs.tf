# ========================================
# EFS File System
# ========================================
resource "aws_efs_file_system" "wordpress" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# ========================================
# EFS Mount Targets (one per subnet)
# ========================================
resource "aws_efs_mount_target" "subnet_1" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.subnet_1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "subnet_2" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.subnet_2.id
  security_groups = [aws_security_group.efs.id]
}
