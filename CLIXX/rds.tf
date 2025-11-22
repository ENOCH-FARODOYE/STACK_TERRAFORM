# ========================================
# RDS Subnet Group
# ========================================

resource "aws_db_subnet_group" "main" {
  provider = aws.dev
  
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ========================================
# RDS Instance (Restored from Snapshot)
# ========================================

resource "aws_db_instance" "main" {
  provider = aws.dev
  
  identifier          = "${var.project_name}-db"
  snapshot_identifier = "clixxwordpressdb"

  # Instance Configuration
  instance_class = "db.t3.micro"
  engine         = "mysql"

  # Storage
  allocated_storage = 20
  storage_type      = "gp2"
  storage_encrypted = false

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability
  multi_az = false

  # Backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Deletion Protection
  skip_final_snapshot = true
  deletion_protection = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "${var.project_name}-db"
  }
}
