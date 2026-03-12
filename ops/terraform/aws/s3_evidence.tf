# ops/terraform/aws/s3_evidence.tf
# Phase 17: The Immutable "Evidence Room"
# This S3 Bucket leverages Object Lock (WORM) to physically prevent modification or deletion
# of compliance artifacts (SBOMs, Trivy Scans, CloudTrail Logs) even by Root Administrators.

# Generate a random suffix to ensure global bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ==========================================
# 1. The Immutable S3 Bucket
# ==========================================
resource "aws_s3_bucket" "security_evidence" {
  bucket = "amazon-clone-security-evidence-${random_id.bucket_suffix.hex}"

  # Enable Object Lock WORM features
  object_lock_enabled = true

  tags = {
    Name        = "amazon-clone-security-evidence"
    Environment = "DevSecOps"
    Phase       = "17"
    Purpose     = "Immutable Audit Log Storage"
  }
}

# ==========================================
# 2. Strict WORM (Write Once, Read Many) Configuration
# ==========================================
resource "aws_s3_bucket_object_lock_configuration" "evidence_lock" {
  bucket = aws_s3_bucket.security_evidence.id

  rule {
    default_retention {
      mode  = "COMPLIANCE" # Strictest mode: Cannot be bypassed or deleted by *anyone* until retention expires
      years = 7          # Standard PCI-DSS/SOC2 retention period
    }
  }
}

# ==========================================
# 3. Security Hardening (Versioning & Encryption)
# ==========================================
# Object Lock requires Versioning to be explicitly enabled
resource "aws_s3_bucket_versioning" "evidence_versioning" {
  bucket = aws_s3_bucket.security_evidence.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Force Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "evidence_encryption" {
  bucket = aws_s3_bucket.security_evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Explicitly Block ALL Public Access
resource "aws_s3_bucket_public_access_block" "evidence_privacy" {
  bucket = aws_s3_bucket.security_evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==========================================
# 4. CloudTrail IAM Write Policy
# ==========================================
# Allow the CloudTrail service to write audit logs directly into this locked bucket
resource "aws_s3_bucket_policy" "cloudtrail_write_policy" {
  bucket = aws_s3_bucket.security_evidence.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.security_evidence.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.security_evidence.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
