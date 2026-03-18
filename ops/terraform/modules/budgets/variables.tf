variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stg, prod)"
  type        = string
}

variable "alerts_sns_topic_arn" {
  description = "SNS Topic ARN for alerts"
  type        = string
}
