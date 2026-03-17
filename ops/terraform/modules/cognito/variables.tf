variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}

variable "user_pool_name" {
  description = "Override the default User Pool name"
  type        = string
  default     = ""
}

variable "app_client_name" {
  description = "Override the default App Client name"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "The base domain name for the hosted UI (e.g., auth-devcloudproject)"
  type        = string
}

variable "callback_urls" {
  description = "A list of valid application URLs the Cognito Hosted UI is allowed to redirect to after successful login"
  type        = list(string)
}

variable "logout_urls" {
  description = "A list of valid application URLs the Cognito Hosted UI is allowed to redirect to after logout"
  type        = list(string)
}

variable "region" {
  description = "The AWS region the Cognito pool is deployed in"
  type        = string
  default     = "us-east-1"
}
