provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  name                 = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_tag_name     = var.cluster_name
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  additional_tags      = var.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name                   = var.cluster_name
  kubernetes_version             = var.kubernetes_version
  vpc_id                         = module.vpc.vpc_id
  private_subnet_ids             = module.vpc.private_subnet_ids
  node_group_name                = var.node_group_name
  node_instance_types            = var.node_instance_types
  node_desired_size              = var.node_desired_size
  node_min_size                  = var.node_min_size
  node_max_size                  = var.node_max_size
  cluster_endpoint_public_access = var.cluster_endpoint_public_access
  additional_tags                = var.tags
}
