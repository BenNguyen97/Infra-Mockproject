resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_sn" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_sn_name
  }
}

resource "aws_subnet" "private_sn" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.private_subnet_az
  tags = {
    Name = var.private_sn_name
  }
}

resource "aws_internet_gateway" "luan_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = var.igw_name
  }
}

# Tạo Elastic IP
resource "aws_eip" "elastic_ip" {
  tags = {
    Name = var.eip_name
  }
}

# Tạo NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id   = aws_eip.elastic_ip.id
  subnet_id       = aws_subnet.public_sn.id
  tags            = {
    Name = var.nat_gw_name
  }
}

# Tạo Route Table cho Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.luan_igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

# Gán Public Subnet vào Public Route Table
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_sn.id
  route_table_id = aws_route_table.public_rt.id
}

# Tạo Route Table cho Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id  # Private traffic đi qua NAT Gateway
  }
  tags = {
    Name = "Private Route Table"
  }
}

# Gán Private Subnet vào Private Route Table
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_sn.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group for EC2
resource "aws_security_group" "mongo_sg" {
  vpc_id = aws_vpc.main_vpc.id

  # Cho phép SSH từ IP cá nhân của bạn
  ingress {
    description = "Allow SSH from personal IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [chomp(data.http.my_ip.response_body) == "" ? "0.0.0.0/0" : "${chomp(data.http.my_ip.response_body)}/32"]
  }

  # Cho phép truy cập MongoDB từ EKS worker nodes
  ingress {
    description     = "Allow MongoDB access from EKS worker nodes"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = var.eks_sg_ids
  }

  # Cho phép tất cả outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Luan-MongoDB-SG"
  }
}
