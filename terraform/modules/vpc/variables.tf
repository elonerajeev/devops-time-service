variable "name" {
  description = "Base name used to name the VPC resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by the subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  type        = list(string)
}

variable "cluster_tag_name" {
  description = "EKS cluster name used in Kubernetes discovery tags."
  type        = string
}

variable "enable_nat_gateway" {
  description = "Whether NAT gateways should be created."
  type        = bool
}

variable "single_nat_gateway" {
  description = "Whether a single NAT gateway should be shared by all private subnets."
  type        = bool
}

variable "additional_tags" {
  description = "Extra tags merged into supported resources."
  type        = map(string)
  default     = {}
}
