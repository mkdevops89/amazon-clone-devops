variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stg, prod)"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS Topic ARN for alerting"
  type        = string
}
