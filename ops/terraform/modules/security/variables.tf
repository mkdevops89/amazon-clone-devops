variable "environment" {
  description = "The target deployment environment (e.g., dev, stg, prod)"
  type        = string
}

variable "project" {
  description = "The global project namespace"
  type        = string
  default     = "amazon-clone"
}

variable "evidence_bucket_id" {
  description = "The ID of the S3 bucket used for immutable CloudTrail logging. Passed in from the S3 module."
  type        = string
}

variable "cloudtrail_s3_policy_arn" {
  description = "The ARN of the S3 Bucket Policy allowing CloudTrail to write. Passed in from the S3 module to establish a explicit dependency."
  type        = string
  default     = ""
}
