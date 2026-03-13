# ops/terraform/aws/security.tf
# Phase 17: AWS Native Security (The "Ephemeral SOC")
# This module deploys AWS GuardDuty, Security Hub, and CloudTrail to actively audit the AWS Account.
# To save costs, GuardDuty and Security Hub are toggleable via var.enable_ephemeral_soc.

variable "enable_ephemeral_soc" {
  description = "Set to true to spin up GuardDuty and Security Hub for portfolio screenshots/audits. MUST BE FALSE normally to save money."
  type        = bool
  default     = false
}

# ==========================================
# 1. AWS Security Hub (CSPM)
# ==========================================
resource "aws_securityhub_account" "portfolio_soc" {
  count = var.enable_ephemeral_soc ? 1 : 0
}

# Automatically subscribe to the AWS Foundational Security Best Practices standard
resource "aws_securityhub_standards_subscription" "fsbp" {
  count         = var.enable_ephemeral_soc ? 1 : 0
  depends_on    = [aws_securityhub_account.portfolio_soc]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

# ==========================================
# 2. Amazon GuardDuty (Machine Learning Threat Detection)
# ==========================================
resource "aws_guardduty_detector" "primary" {
  count = var.enable_ephemeral_soc ? 1 : 0
  enable = true
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name        = "amazon-clone-guardduty"
    Environment = "DevSecOps"
    Phase       = "17"
  }
}

# ==========================================
# 3. AWS CloudTrail (Persistent API Auditing)
# ==========================================
# CloudTrail is intentionally NOT toggleable. 
# Basic Management Event history is free, but we are creating a dedicated active trail to ship to S3.
resource "aws_cloudtrail" "account_audit" {
  name                          = "amazon-clone-management-events"
  s3_bucket_name                = aws_s3_bucket.security_evidence.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_write_policy
  ]

  tags = {
    Name        = "amazon-clone-cloudtrail"
    Environment = "DevSecOps"
    Phase       = "17"
  }
}

data "aws_region" "current" {}
