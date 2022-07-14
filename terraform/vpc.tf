variable "region" {
  default     = "ap-northeast-2"
  description = "AWS region"
}

provider "aws" {
  region = var.region
}

locals {
  cluster_name = "eks-lab-cluster"
  vpc_name = "eks-dev"
}

module "vpc" {
#  source = "terraform-aws-modules/vpc/aws"
  source = "./modules/vpc"

  name = local.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

output "cluster_name" {
  value = local.cluster_name
}

output "vpc_name" {
  value = local.vpc_name
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "region" {
  value = local.region
}