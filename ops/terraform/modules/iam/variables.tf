variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}

variable "cost_explorer_policy_name" {
  description = "Override the default Cost Explorer policy name"
  type        = string
  default     = ""
}

variable "bedrock_policy_name" {
  description = "Override the default Bedrock policy name"
  type        = string
  default     = ""
}
