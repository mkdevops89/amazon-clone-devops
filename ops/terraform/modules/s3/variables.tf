variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}
