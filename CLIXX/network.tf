##############################################################################
# VPC and Networking - 12 Subnet 
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

##############################################################################
# Public Subnets (2)
##############################################################################

resource "aws_subnet" "public_1" {
  provider = aws.dev

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network_config.public_subnet_1_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_config.project_name}-public-subnet-1"
    Type = "Public"
    Tier = "ALB-Bastion"
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
    Tier = "ALB-Bastion"
  }
}

##############################################################################
# Private Subnets - App Servers (2)
##############################################################################

resource "aws_subnet" "private_app_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_app_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-app-subnet-1"
    Type = "Private"
    Tier = "Application"
  }
}

resource "aws_subnet" "private_app_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_app_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-app-subnet-2"
    Type = "Private"
    Tier = "Application"
  }
}

##############################################################################
# Private Subnets - MySQL RDS (2)
##############################################################################

resource "aws_subnet" "private_mysql_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_mysql_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-mysql-subnet-1"
    Type = "Private"
    Tier = "Database-MySQL"
  }
}

resource "aws_subnet" "private_mysql_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_mysql_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-mysql-subnet-2"
    Type = "Private"
    Tier = "Database-MySQL"
  }
}

##############################################################################
# Private Subnets - Oracle DB (2)
##############################################################################

resource "aws_subnet" "private_oracle_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_oracle_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-oracle-subnet-1"
    Type = "Private"
    Tier = "Database-Oracle"
  }
}

resource "aws_subnet" "private_oracle_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_oracle_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-oracle-subnet-2"
    Type = "Private"
    Tier = "Database-Oracle"
  }
}

##############################################################################
# Private Subnets - Java App DB (2)
##############################################################################

resource "aws_subnet" "private_java_db_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_java_db_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-java-db-subnet-1"
    Type = "Private"
    Tier = "Database-Java"
  }
}

resource "aws_subnet" "private_java_db_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_java_db_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-java-db-subnet-2"
    Type = "Private"
    Tier = "Database-Java"
  }
}

##############################################################################
# Private Subnets - Java App Server (2)
##############################################################################

resource "aws_subnet" "private_java_app_1" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_java_app_subnet_1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.environment_config.project_name}-private-java-app-subnet-1"
    Type = "Private"
    Tier = "Application-Java"
  }
}

resource "aws_subnet" "private_java_app_2" {
  provider = aws.dev

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network_config.private_java_app_subnet_2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.environment_config.project_name}-private-java-app-subnet-2"
    Type = "Private"
    Tier = "Application-Java"
  }
}

##############################################################################
# Route Tables
##############################################################################

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

##############################################################################
# Route Table Associations - Public Subnets
##############################################################################

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

##############################################################################
# Route Table Associations - Private Subnets
##############################################################################

resource "aws_route_table_association" "private_app_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_app_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_app_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_mysql_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_mysql_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_mysql_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_mysql_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_oracle_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_oracle_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_oracle_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_oracle_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_java_db_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_java_db_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_java_db_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_java_db_2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_java_app_1" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_java_app_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_java_app_2" {
  provider = aws.dev

  subnet_id      = aws_subnet.private_java_app_2.id
  route_table_id = aws_route_table.private.id
}
