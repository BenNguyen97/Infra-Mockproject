# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
#   enable_dns_support = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "eks-vpc"
#   }
# }

# resource "aws_subnet" "public" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "us-east-1a"
# }

# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.2.0/24"
#   availability_zone = "us-east-1b"
# }

# resource "aws_security_group" "eks" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "eks-sg"
#   }
# }
# resource "aws_instance" "mongodb" {
#   ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
#   instance_type = "t3.micro"
#   subnet_id     = module.networking.public_subnet_id
#   security_groups = [module.networking.mongodb_sg]

#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y mongodb-org
#     systemctl start mongod
#     systemctl enable mongod
#   EOF

#   tags = {
#     Name = "MongoDB-Server"
#   }
# }
resource "aws_instance" "mongodb" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  security_groups = [var.security_group_id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y mongodb-org
    systemctl start mongod
    systemctl enable mongod
  EOF

  tags = {
    Name = var.instance_name
  }
}
