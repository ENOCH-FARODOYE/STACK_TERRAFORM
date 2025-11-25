##############################################################################
# Launch Template - Dev Account
##############################################################################

# Data source - get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  provider    = aws.dev
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template
resource "aws_launch_template" "main" {
  provider = aws.dev

  name_prefix   = "${var.project_name}-lt-"
  description   = "Launch template for CliXX WordPress application"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.main.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(file("${path.module}/bootstrap.sh"))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-launch-template"
  }
}
