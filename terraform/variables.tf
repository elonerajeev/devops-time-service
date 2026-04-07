terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region where the EKS cluster and networking resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name used for the EKS cluster and related infrastructure."
  type        = string
  default     = "simple-time-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Exactly two availability zones used for the public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets that host the EKS worker nodes."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateways for private subnet egress."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Whether to create a single shared NAT gateway instead of one per availability zone."
  type        = bool
  default     = true
}

variable "node_group_name" {
  description = "Name of the EKS managed node group."
  type        = string
  default     = "primary"
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["m6a.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 2
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is reachable from the public internet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all supported resources."
  type        = map(string)
  default = {
    Project     = "devops-time-service"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
