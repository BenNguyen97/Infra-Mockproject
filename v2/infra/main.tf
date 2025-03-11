terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# Networking
module "networking" {
  source             = "./modules/networking"
  vpc_cidr           = var.vpc_cidr
  vpc_name           = var.vpc_name
  
  public_subnet_cidr = var.public_subnet_cidr
  public_subnet_az   = var.public_subnet_az
  public_sn_name     = var.public_sn_name

  private_subnet_cidr = var.private_subnet_cidr
  private_subnet_az  = var.private_subnet_az
  private_sn_name    = var.private_sn_name
  

  igw_name           = var.igw_name
  eip_name           = var.eip_name
  nat_gw_name        = var.nat_gw_name
  eks_sg_ids         = var.eks_sg_ids
}

# EKS Cluster
module "eks" {
  source          = "./modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = [module.networking.private_subnet_id]
  vpc_id          = module.networking.vpc_id
}

# EC2 MongoDB
module "ec2" {
  source             = "./modules/ec2"
  ami                = var.ami
  instance_type      = var.instance_type
  subnet_id          = module.networking.public_subnet_id
  security_group_id  = module.networking.vpc_id
  instance_name      = "MongoDB-Server"
}
