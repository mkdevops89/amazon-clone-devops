variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "amazon-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "Public Subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "private_subnets" {
  description = "Private Subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "amazon-cluster-v2"
}

variable "db_name" {
  description = "RDS Database Name"
  type        = string
  default     = "amazon-db-v2"
}

variable "db_username" {
  description = "Database Administrator Username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "redis_cluster_id" {
  description = "Redis Cluster ID"
  type        = string
  default     = "amazon-redis-v2"
}
