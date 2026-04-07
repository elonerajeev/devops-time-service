variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID used by the EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where the control plane ENIs and worker nodes are deployed."
  type        = list(string)
}

variable "node_group_name" {
  description = "Managed node group name."
  type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired size of the managed node group."
  type        = number
}

variable "node_min_size" {
  description = "Minimum size of the managed node group."
  type        = number
}

variable "node_max_size" {
  description = "Maximum size of the managed node group."
  type        = number
}

variable "cluster_endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly reachable."
  type        = bool
}

variable "additional_tags" {
  description = "Extra tags merged into supported resources."
  type        = map(string)
  default     = {}
}
