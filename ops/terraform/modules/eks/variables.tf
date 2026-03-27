variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}

variable "region" {
  description = "The AWS Region"
  type        = string
  default     = "us-east-1"
}

# --- VPC & Networking Inputs ---
variable "vpc_id" {
  description = "The ID of the VPC from the vpc module"
  type        = string
}

variable "private_subnets" {
  description = "The private subnets from the vpc module"
  type        = list(string)
}

variable "public_subnets" {
  description = "The public subnets from the vpc module"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC from the vpc module"
  type        = string
}

# --- Compute Engine Inputs ---
variable "cluster_name" {
  description = "The EKS cluster name"
  type        = string
  default     = "amazon-clone-cluster"
}

variable "db_name" {
  description = "The RDS MySQL instance name"
  type        = string
  default     = "amazon-clone-db"
}

variable "snapshot_identifier" {
  description = "The ARN or name of the AWS RDS snapshot to restore from"
  type        = string
  default     = null
}

variable "db_username" {
  description = "The RDS MySQL Master Username"
  type        = string
  default     = "admin"
}

variable "redis_cluster_id" {
  description = "The ElastiCache Redis cluster identifier"
  type        = string
  default     = "amazon-clone-redis"
}

variable "db_subnet_group_name" {
  description = "Override the default DB subnet group name"
  type        = string
  default     = ""
}

variable "redis_subnet_group_name" {
  description = "Override the default Redis subnet group name"
  type        = string
  default     = ""
}

variable "mq_broker_name" {
  description = "Override the default MQ broker name"
  type        = string
  default     = ""
}

variable "db_sg_name" {
  description = "Override the default DB security group name"
  type        = string
  default     = ""
}

variable "redis_sg_name" {
  description = "Override the default Redis security group name"
  type        = string
  default     = ""
}

variable "mq_sg_name" {
  description = "Override the default MQ security group name"
  type        = string
  default     = ""
}

# --- IAM Policy Injection ---
variable "cost_explorer_policy_arn" {
  description = "The Cost Explorer IAM policy ARN"
  type        = string
}

variable "bedrock_invoke_policy_arn" {
  description = "The Bedrock Invoke IAM policy ARN"
  type        = string
}

variable "reports_upload_policy_arn" {
  description = "The Reports S3 upload IAM policy ARN"
  type        = string
}
