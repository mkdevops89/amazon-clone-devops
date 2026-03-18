variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, stg, prod)"
  type        = string
}

variable "domain_name" {
  description = "The primary domain name"
  type        = string
}

variable "route53_zone_id" {
  description = "The Route53 Zone ID"
  type        = string
}
