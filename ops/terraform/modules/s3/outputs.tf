output "s3_images_bucket_id" {
  description = "The ID of the amazon-clone images bucket"
  value       = aws_s3_bucket.product_images.id
}

output "s3_reports_bucket_id" {
  description = "The ID of the DevSecOps pipeline reports bucket"
  value       = aws_s3_bucket.reports.id
}

output "s3_evidence_bucket_id" {
  description = "The ID of the WORM compliance evidence bucket"
  value       = aws_s3_bucket.security_evidence.id
}
