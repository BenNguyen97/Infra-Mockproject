variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "Luan-eks-vpc"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "public_subnet_az" {
  default = "ap-southeast-1a"
}

variable "private_subnet_az" {
  default = "ap-southeast-1b"
}

variable "public_sn_name" {
  default = "luan_public_sn"
}

variable "private_sn_name" {
  default = "luan_private_sn"
}

variable "cluster_name" {
  default = "my-eks-cluster"
}

variable "cluster_version" {
  default = "1.27"
}

variable "ami" {
  default = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  default = "t3.micro"
}
