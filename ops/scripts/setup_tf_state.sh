#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
DYNAMODB_TABLE="amazon-clone-tf-locks"

# 1. Get AWS Account ID
echo "Fetching AWS Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: Could not fetch AWS Account ID. Please configure 'aws configure' first."
    exit 1
fi

BUCKET_NAME="amazon-clone-tfstate-${ACCOUNT_ID}"
echo "Target S3 Bucket: $BUCKET_NAME"

# 2. Create S3 Bucket (if not exists)
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists."
else
    echo "Creating bucket $BUCKET_NAME..."
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
fi

# 3. Enable Versioning
echo "Enabling versioning on $BUCKET_NAME..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

# 4. Enable Encryption
echo "Enabling encryption on $BUCKET_NAME..."
aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# 5. Create DynamoDB Table for Locking
echo "Checking DynamoDB table $DYNAMODB_TABLE..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
    echo "Table $DYNAMODB_TABLE already exists."
else
    echo "Creating table $DYNAMODB_TABLE..."
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$REGION"
fi

# 6. Generate backend.tf
echo "Generating backend.tf..."
cat <<EOF > ../terraform/aws/backend.tf
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "global/s3/terraform.tfstate"
    region         = "$REGION"
    dynamodb_table = "$DYNAMODB_TABLE"
    encrypt        = true
  }
}
EOF

echo "----------------------------------------------------------------"
echo "✅ Backend infrastructure ready!"
echo "Bucket: $BUCKET_NAME"
echo "Table:  $DYNAMODB_TABLE"
echo "backend.tf has been generated."
echo "----------------------------------------------------------------"
