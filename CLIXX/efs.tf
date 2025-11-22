# ========================================
# EFS File System
# ========================================

resource "aws_efs_file_system" "main" {
  provider = aws.dev
  
  creation_token = "${var.project_name}-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${var.project_name}-efs"
  }
}

# ========================================
# EFS Mount Targets
# ========================================

# Mount Target in Subnet 1
resource "aws_efs_mount_target" "subnet_1" {
  provider = aws.dev
  
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.subnet_1.id
  security_groups = [aws_security_group.efs.id]
}

# Mount Target in Subnet 2
resource "aws_efs_mount_target" "subnet_2" {
  provider = aws.dev
  
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.subnet_2.id
  security_groups = [aws_security_group.efs.id]
}
