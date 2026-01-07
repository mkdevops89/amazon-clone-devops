#!/bin/bash
set -e

# Configuration
BUCKET_NAME="amazon-clone-tf-state-$(date +%s)" # Unique bucket name
TABLE_NAME="terraform-locks"
REGION="us-east-1"

echo "==================================================="
echo "   Setting up Terraform Backend (S3 + DynamoDB)"
echo "==================================================="

# 1. Create S3 Bucket
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "✅ Bucket $BUCKET_NAME already exists."
else
    echo "Creating S3 Bucket: $BUCKET_NAME..."
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    
    # Enable Versioning (Critical for State Recovery)
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
    echo "✅ Bucket Created and Versioning Enabled."
fi

# 2. Create DynamoDB Table for Locking
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" >/dev/null 2>&1; then
    echo "✅ DynamoDB Table $TABLE_NAME already exists."
else
    echo "Creating DynamoDB Table: $TABLE_NAME..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
    echo "✅ DynamoDB Table Created."
fi

# 3. Generate backend.tf configuration
cat <<EOF > ../terraform/aws/backend.tf
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "global/s3/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$TABLE_NAME"
    encrypt        = true
  }
}
EOF

echo "==================================================="
echo "✅ Configuration generated at: ../terraform/aws/backend.tf"
echo "   Bucket: $BUCKET_NAME"
echo "   Table:  $TABLE_NAME"
echo "==================================================="
echo "👉 NOW RUN: cd ../terraform/aws && terraform init"
