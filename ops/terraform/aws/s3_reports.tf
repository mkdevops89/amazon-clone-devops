# ==========================================
# Phase 6d: S3 Bucket for Scan Reports
# ==========================================
resource "random_id" "reports_bucket_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "reports" {
  bucket = "amazon-clone-reports-${random_id.reports_bucket_suffix.hex}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports_encryption" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "reports_public_access" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ==========================================
# IAM Policy for EKS Nodes to Upload Reports
# ==========================================
resource "aws_iam_policy" "reports_upload_policy" {
  name        = "AmazonCloneReportsUploadPolicy"
  description = "Allows EKS nodes to upload security reports to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket" 
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.reports.arn,
          "${aws_s3_bucket.reports.arn}/*"
        ]
      }
    ]
  })
}
