# ========================================
# VPC
# ========================================
resource "aws_vpc" "main" {
  provider = aws.dev
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ========================================
# Internet Gateway
# ========================================
resource "aws_internet_gateway" "main" {
  provider = aws.dev
  
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ========================================
# Public Subnets (for ALB, EC2, RDS, EFS)
# ========================================
resource "aws_subnet" "subnet_1" {
  provider = aws.dev
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_1_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  provider = aws.dev
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_2_cidr
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-2"
  }
}

# ========================================
# Route Table
# ========================================
resource "aws_route_table" "main" {
  provider = aws.dev
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

# Associate Subnets with Route Table
resource "aws_route_table_association" "subnet_1" {
  provider = aws.dev
  
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "subnet_2" {
  provider = aws.dev
  
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.main.id
}
