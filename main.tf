terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# Fetch public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Luan-Main-VPC"
  }
}

# Subnet 1
resource "aws_subnet" "main_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Luan-Main-Subnet-1"
  }
}

# Subnet 2 
resource "aws_subnet" "main_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Luan-Main-Subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "Luan-Main-IGW"
  }
}

# Route Table
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "main_route_assoc_1" {
  subnet_id      = aws_subnet.main_subnet_1.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "main_route_assoc_2" {
  subnet_id      = aws_subnet.main_subnet_2.id
  route_table_id = aws_route_table.main_route_table.id
}

#Security Group for EKS Nodes
resource "aws_security_group" "eks_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Luan-EKS-SG"
  }
}

# Security Group for MongoDB EC2
resource "aws_security_group" "mongo_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  ingress {
    description = "Allow MongoDB access from EKS"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_sg.id]
  }

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

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_role" {
  name = "Luan-EKS-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Role for EKS Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "Luan-EKS-Node-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })  
  # Attach policies for EKS worker nodes
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "Luan-eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  }

  depends_on = [aws_iam_role.eks_role]
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}


# EKS Node Group
resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.main_subnet_1.id, aws_subnet.main_subnet_2.id]
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  depends_on = [aws_iam_role.eks_node_role, aws_eks_cluster.eks_cluster]
}

# EC2 Instance for MongoDB
resource "aws_instance" "mongodb" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main_subnet_1.id
  key_name      = var.key_name
  security_groups = [aws_security_group.mongo_sg.id]

  user_data = file("user_data/mongodb.sh")

  tags = {
    Name = "Luan-MongoDB-Instance"
  }
}

# Fetch AMI for Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
