# Random string for global uniqueness of the image bucket
resource "random_id" "image_bucket_suffix" {
  byte_length = 4
}

# The actual standard S3 bucket to hold your storefront images
resource "aws_s3_bucket" "product_images" {
  bucket = "amazon-clone-product-images-${random_id.image_bucket_suffix.hex}"

  tags = {
    Name        = "Amazon Clone Product Images"
    Environment = "Dev"
  }
}

# Explicitly disable "Block Public Access" properties so browsers can read the images
resource "aws_s3_bucket_public_access_block" "product_images_public" {
  bucket = aws_s3_bucket.product_images.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Attach a bucket policy granting "s3:GetObject" permission to the entire internet (Principal = "*")
resource "aws_s3_bucket_policy" "product_images_open_read" {
  bucket = aws_s3_bucket.product_images.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.product_images.arn}/*"
      }
    ]
  })

  # We must apply this Policy *after* the Public Access Block is completely lifted
  depends_on = [aws_s3_bucket_public_access_block.product_images_public]
}

# Configure CORS so your React application isn't blocked by the browser when loading images
resource "aws_s3_bucket_cors_configuration" "product_images_cors" {
  bucket = aws_s3_bucket.product_images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] # In Production, this should be "https://devcloudproject.com"
    expose_headers  = []
    max_age_seconds = 3000
  }
}
