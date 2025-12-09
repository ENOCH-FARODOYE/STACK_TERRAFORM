##############################################################################
# CliXX WordPress Infrastructure - Main Configuration
##############################################################################

##############################################################################
# VPC and Networking
##############################################################################

# VPC
resource "aws_vpc" "main" {
  provider = aws.dev

  cidr_block           = var.network_config.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment_config.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  provider = aws.dev

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-igw"
  }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  provider = aws.dev

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network_config.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_config.project_name}-public-subnet-1"
    Type = "Public"
  }
}

resource "aws_subnet" "public_2" {
  provider = aws.dev

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network_config.public_subnet_2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_config.project_name}-public-subnet-2"
    Type = "Public"
  }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-subnet-1"
    Type = "Private"
  }
}

resource "aws_subnet" "private_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-subnet-2"
    Type = "Private"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  provider = aws.dev

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment_config.project_name}-public-rt"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  provider = aws.dev

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-private-rt"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

##############################################################################
# Security Groups (Created with Map Variables)
##############################################################################

# ALB Security Group
resource "aws_security_group" "alb" {
  provider = aws.dev

  name        = "${var.environment_config.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-alb-sg"
  }
}

# ALB Ingress Rules (from map)
resource "aws_security_group_rule" "alb_ingress" {
  provider = aws.dev

  count = length(var.security_group_rules.alb_ingress_rules)

  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  description       = var.security_group_rules.alb_ingress_rules[count.index].description
  from_port         = var.security_group_rules.alb_ingress_rules[count.index].from_port
  to_port           = var.security_group_rules.alb_ingress_rules[count.index].to_port
  protocol          = var.security_group_rules.alb_ingress_rules[count.index].protocol
  cidr_blocks       = var.security_group_rules.alb_ingress_rules[count.index].cidr_blocks
}

# ALB Egress Rule
resource "aws_security_group_rule" "alb_egress" {
  provider = aws.dev

  type              = "egress"
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  provider = aws.dev

  name        = "${var.environment_config.project_name}-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-ec2-sg"
  }
}

# EC2 Ingress Rules (from map)
resource "aws_security_group_rule" "ec2_ingress" {
  provider = aws.dev

  count = length(var.security_group_rules.ec2_ingress_rules)

  type              = "ingress"
  security_group_id = aws_security_group.ec2.id
  description       = var.security_group_rules.ec2_ingress_rules[count.index].description
  from_port         = var.security_group_rules.ec2_ingress_rules[count.index].from_port
  to_port           = var.security_group_rules.ec2_ingress_rules[count.index].to_port
  protocol          = var.security_group_rules.ec2_ingress_rules[count.index].protocol
  cidr_blocks       = try(var.security_group_rules.ec2_ingress_rules[count.index].cidr_blocks, null)
  source_security_group_id = try(
    var.security_group_rules.ec2_ingress_rules[count.index].source_sg_type == "alb" ? aws_security_group.alb.id : null,
    null
  )
}

# EC2 Egress Rule
resource "aws_security_group_rule" "ec2_egress" {
  provider = aws.dev

  type              = "egress"
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# RDS Security Group
resource "aws_security_group" "rds" {
  provider = aws.dev

  name        = "${var.environment_config.project_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-rds-sg"
  }
}

# RDS Ingress Rules (from map)
resource "aws_security_group_rule" "rds_ingress" {
  provider = aws.dev

  count = length(var.security_group_rules.rds_ingress_rules)

  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  description              = var.security_group_rules.rds_ingress_rules[count.index].description
  from_port                = var.security_group_rules.rds_ingress_rules[count.index].from_port
  to_port                  = var.security_group_rules.rds_ingress_rules[count.index].to_port
  protocol                 = var.security_group_rules.rds_ingress_rules[count.index].protocol
  source_security_group_id = aws_security_group.ec2.id
}

# RDS Egress Rule
resource "aws_security_group_rule" "rds_egress" {
  provider = aws.dev

  type              = "egress"
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# EFS Security Group
resource "aws_security_group" "efs" {
  provider = aws.dev

  name        = "${var.environment_config.project_name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.environment_config.project_name}-efs-sg"
  }
}

# EFS Ingress Rules (from map)
resource "aws_security_group_rule" "efs_ingress" {
  provider = aws.dev

  count = length(var.security_group_rules.efs_ingress_rules)

  type                     = "ingress"
  security_group_id        = aws_security_group.efs.id
  description              = var.security_group_rules.efs_ingress_rules[count.index].description
  from_port                = var.security_group_rules.efs_ingress_rules[count.index].from_port
  to_port                  = var.security_group_rules.efs_ingress_rules[count.index].to_port
  protocol                 = var.security_group_rules.efs_ingress_rules[count.index].protocol
  source_security_group_id = aws_security_group.ec2.id
}

# EFS Egress Rule
resource "aws_security_group_rule" "efs_egress" {
  provider = aws.dev

  type              = "egress"
  security_group_id = aws_security_group.efs.id
  description       = "Allow all outbound"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

##############################################################################
# IAM Roles - Management Account SSM Access + Dev Account EC2 Role
##############################################################################

# Trust policy - allows Dev account roles to assume this role
data "aws_iam_policy_document" "ssm_assume_role" {
  # Allow Dev account Engineering role
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.environment_config.dev_account_id}:role/${var.environment_config.engineering_role_name}"]
    }

    actions = ["sts:AssumeRole"]
  }

  # Allow Dev account EC2 role
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ec2_instance.arn]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.iam_config.external_id]
    }
  }
}

# IAM Role - Management Account
resource "aws_iam_role" "ssm_parameter_access" {
  name               = var.iam_config.ssm_role_name
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role.json

  tags = {
    Name        = var.iam_config.ssm_role_name
    Application = "CliXX"
    Purpose     = "Allow Dev account to access CliXX SSM parameters"
  }

  depends_on = [aws_iam_role.ec2_instance]
}

# Policy - allows reading and writing SSM parameters
data "aws_iam_policy_document" "ssm_access_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:PutParameter"
    ]
    resources = [
      "arn:aws:ssm:${var.environment_config.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.iam_config.ssm_parameter_path_prefix}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
}

# Attach policy to role
resource "aws_iam_role_policy" "ssm_access_policy" {
  name   = "SSMParameterAccessPolicy"
  role   = aws_iam_role.ssm_parameter_access.id
  policy = data.aws_iam_policy_document.ssm_access_policy.json
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance" {
  provider = aws.dev

  name = "${var.environment_config.project_name}-${var.iam_config.ec2_role_name_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.environment_config.project_name}-${var.iam_config.ec2_role_name_suffix}"
  }
}

# Policy - allows assuming Management Account SSM role
resource "aws_iam_role_policy" "assume_mgmt_ssm_role" {
  provider = aws.dev

  name = "${var.environment_config.project_name}-assume-mgmt-ssm-policy"
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${var.environment_config.management_account_id}:role/${var.iam_config.ssm_role_name}"
      }
    ]
  })
}

# Policy attachments - basic EC2 permissions
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  provider = aws.dev

  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  provider = aws.dev

  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  provider = aws.dev

  name = "${var.environment_config.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Name = "${var.environment_config.project_name}-ec2-instance-profile"
  }
}

##############################################################################
# RDS Database (Properties from Map Variable)
##############################################################################

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  provider = aws.dev

  name       = "${var.environment_config.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.environment_config.project_name}-db-subnet-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  provider = aws.dev

  identifier          = var.database_config.identifier
  snapshot_identifier = var.database_config.snapshot_identifier

  # Instance Configuration
  instance_class = var.database_config.instance_class
  engine         = var.database_config.engine

  # Storage
  storage_type      = var.database_config.storage_type
  storage_encrypted = var.database_config.storage_encrypted

  # Network - Private Subnets
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High Availability
  multi_az = var.database_config.multi_az

  # Backup
  backup_retention_period = var.database_config.backup_retention_period
  backup_window           = var.database_config.backup_window
  maintenance_window      = var.database_config.maintenance_window

  # Deletion Protection
  skip_final_snapshot       = var.database_config.skip_final_snapshot
  final_snapshot_identifier = "${var.database_config.identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = var.database_config.deletion_protection

  # Monitoring
  enabled_cloudwatch_logs_exports = var.database_config.enable_cloudwatch_logs

  tags = {
    Name = var.database_config.identifier
  }
}

##############################################################################
# EFS File System (Properties from Map Variable)
##############################################################################

resource "aws_efs_file_system" "main" {
  provider = aws.dev

  creation_token   = var.efs_config.creation_token
  encrypted        = var.efs_config.encrypted
  performance_mode = var.efs_config.performance_mode
  throughput_mode  = var.efs_config.throughput_mode

  lifecycle_policy {
    transition_to_ia = var.efs_config.transition_to_ia_days
  }

  tags = {
    Name = "${var.environment_config.project_name}-efs"
  }
}

# EFS Mount Targets
resource "aws_efs_mount_target" "subnet_1" {
  provider = aws.dev

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.public_1.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "subnet_2" {
  provider = aws.dev

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = aws_subnet.public_2.id
  security_groups = [aws_security_group.efs.id]
}

##############################################################################
# Application Load Balancer (Properties from Map Variable)
##############################################################################

resource "aws_lb" "main" {
  provider = aws.dev

  name               = "${var.environment_config.project_name}-alb"
  internal           = var.alb_config.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection       = var.alb_config.enable_deletion_protection
  enable_http2                     = var.alb_config.enable_http2
  enable_cross_zone_load_balancing = var.alb_config.enable_cross_zone_lb

  tags = {
    Name = "${var.environment_config.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  provider = aws.dev

  name     = "${var.environment_config.project_name}-tg"
  port     = var.alb_config.target_group_port
  protocol = var.alb_config.target_group_protocol
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = var.alb_config.health_check_healthy_threshold
    unhealthy_threshold = var.alb_config.health_check_unhealthy_threshold
    timeout             = var.alb_config.health_check_timeout
    interval            = var.alb_config.health_check_interval
    path                = var.alb_config.health_check_path
    protocol            = var.alb_config.target_group_protocol
    matcher             = var.alb_config.health_check_matcher
  }

  deregistration_delay = var.alb_config.deregistration_delay

  stickiness {
    type            = "lb_cookie"
    cookie_duration = var.alb_config.stickiness_duration
    enabled         = var.alb_config.stickiness_enabled
  }

  tags = {
    Name = "${var.environment_config.project_name}-tg"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  provider = aws.dev

  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

##############################################################################
# EC2 Key Pair
##############################################################################

# Generate private key
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "main" {
  provider = aws.dev

  key_name   = "${var.compute_config.key_name_prefix}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.compute_config.key_name_prefix}-key"
  }
}

# Save private key to local file
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/${var.compute_config.key_name_prefix}-key.pem"
  file_permission = "0400"
}

##############################################################################
# Launch Template (EC2 Properties from Map Variable)
##############################################################################

resource "aws_launch_template" "main" {
  provider = aws.dev

  name_prefix   = "${var.environment_config.project_name}-lt-"
  description   = "Launch template for ${var.environment_config.project_name} WordPress application"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.compute_config.instance_type
  key_name      = aws_key_pair.main.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = filebase64("${path.module}/bootstrap.sh")

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = var.compute_config.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.environment_config.project_name}-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.environment_config.project_name}-volume"
    }
  }

  tags = {
    Name = "${var.environment_config.project_name}-launch-template"
  }
}

##############################################################################
# Auto Scaling Group (Properties from Map Variable)
##############################################################################

resource "aws_autoscaling_group" "main" {
  provider = aws.dev

  name                      = "${var.environment_config.project_name}-asg"
  vpc_zone_identifier       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns         = [aws_lb_target_group.main.arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.compute_config.health_check_grace_period
  default_cooldown          = var.compute_config.default_cooldown
  min_size                  = var.compute_config.asg_min_size
  max_size                  = var.compute_config.asg_max_size
  desired_capacity          = var.compute_config.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupTotalInstances"
  ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment_config.project_name}-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Application"
    value               = "CliXX"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Tracking Scaling Policy - CPU
resource "aws_autoscaling_policy" "cpu_scaling" {
  provider = aws.dev

  name                   = "${var.environment_config.project_name}-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.compute_config.cpu_target_value
  }
}

# Target Tracking Scaling Policy - ALB Request Count
resource "aws_autoscaling_policy" "alb_request_count" {
  provider = aws.dev

  name                   = "${var.environment_config.project_name}-alb-request-count"
  autoscaling_group_name = aws_autoscaling_group.main.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.main.arn_suffix}"
    }
    target_value = var.compute_config.alb_request_target_value
  }
}

##############################################################################
# Route 53 DNS
##############################################################################

resource "aws_route53_record" "clixx_dev" {
  provider = aws

  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.route53_config.record_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = var.route53_config.evaluate_target_health
  }
}

##############################################################################
# SSM Parameters - Management Account
##############################################################################

# EFS ID
resource "aws_ssm_parameter" "efs_id" {
  provider = aws

  name        = "${var.iam_config.ssm_parameter_path_prefix}/efs/id"
  description = "${var.environment_config.project_name} EFS File System ID"
  type        = "String"
  value       = aws_efs_file_system.main.id
  overwrite   = true

  tags = {
    Name        = "${var.environment_config.project_name}-efs-id"
    Application = "CliXX"
  }
}

# RDS Endpoint
resource "aws_ssm_parameter" "rds_endpoint" {
  provider = aws

  name        = "${var.iam_config.ssm_parameter_path_prefix}/rds/endpoint"
  description = "${var.environment_config.project_name} RDS Database Endpoint"
  type        = "String"
  value       = aws_db_instance.main.endpoint
  overwrite   = true

  tags = {
    Name        = "${var.environment_config.project_name}-rds-endpoint"
    Application = "CliXX"
  }
}

# Database Name
resource "aws_ssm_parameter" "db_name" {
  provider = aws

  name        = "${var.iam_config.ssm_parameter_path_prefix}/rds/database"
  description = "${var.environment_config.project_name} Database Name"
  type        = "String"
  value       = var.database_config.db_name
  overwrite   = true

  tags = {
    Name        = "${var.environment_config.project_name}-db-name"
    Application = "CliXX"
  }
}

# Database Username
resource "aws_ssm_parameter" "db_username" {
  provider = aws

  name        = "${var.iam_config.ssm_parameter_path_prefix}/rds/username"
  description = "${var.environment_config.project_name} Database Username"
  type        = "String"
  value       = var.database_config.db_username
  overwrite   = true

  tags = {
    Name        = "${var.environment_config.project_name}-db-username"
    Application = "CliXX"
  }
}

# Database Password (SecureString)
resource "aws_ssm_parameter" "db_password" {
  provider = aws

  name        = "${var.iam_config.ssm_parameter_path_prefix}/rds/password"
  description = "${var.environment_config.project_name} Database Password"
  type        = "SecureString"
  value       = var.db_password
  overwrite   = true

  tags = {
    Name        = "${var.environment_config.project_name}-db-password"
    Application = "CliXX"
  }
}
