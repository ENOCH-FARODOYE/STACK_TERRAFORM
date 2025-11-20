# ========================================
# DB Subnet Group
# ========================================
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ========================================
# RDS Instance (Restore from Snapshot)
# ========================================
resource "aws_db_instance" "wordpress" {
  identifier     = var.db_identifier
  instance_class = var.db_instance_class

  # Restore from snapshot
  snapshot_identifier = var.db_snapshot_identifier

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = true

  # Storage
  # allocated_storage = var.db_allocated_storage

  tags = {
    Name = "${var.project_name}-db"
  }
}
