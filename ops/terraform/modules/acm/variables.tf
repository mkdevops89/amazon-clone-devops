variable "domain_name" {
  description = "The domain name for the certificate"
  type        = string
}

variable "environment" {
  description = "Environment string"
  type        = string
  default     = "dev"
}
