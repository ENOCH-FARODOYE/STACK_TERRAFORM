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
