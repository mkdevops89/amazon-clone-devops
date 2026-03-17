variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}

variable "iam_role_name" {
  description = "Override the default IAM role name"
  type        = string
  default     = ""
}

variable "sns_topic_name" {
  description = "Override the default SNS topic name"
  type        = string
  default     = ""
}

variable "lambda_role_name" {
  description = "The IAM Role Name the lambda executes under"
  type        = string
}
