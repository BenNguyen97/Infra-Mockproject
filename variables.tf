# AWS Region
variable "region" {
  description = "AWS region to deploy resources"
  default     = "ap-southeast-1" 
}

# CIDR Blocks
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

# tạo khóa SSH
resource "tls_private_key" "key_pem" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# SSH Key Pair Name
variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = "luan_key"
}

# Tạo Key Pair trong AWS
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.key_pem.public_key_openssh
}

# Lưu private key cục bộ
resource "local_file" "private_key" {
  content   = tls_private_key.key_pem.private_key_pem
  filename = "${var.key_name}.pem" # Lưu tệp private key với định dạng PEM
}

# Instance Type
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

# IP Address for Security Group
variable "my_ip"{
  description = "Your IP address in CIDR format"
  default     = "0.0.0.0/0" # Thay bằng IP thực tế của bạn
}