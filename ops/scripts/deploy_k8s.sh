#!/bin/bash
set -e

# Configuration
export AWS_REGION="us-east-1"

# Fetch Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Using Account ID: $AWS_ACCOUNT_ID"

echo "Applying Kubernetes Manifests..."

# Function to apply manifest with envsubst
apply_manifest() {
    local file=$1
    echo "📄 Processing $file..."
    # Substitute AWS_ACCOUNT_ID only
    envsubst '${AWS_ACCOUNT_ID}' < "$file" | kubectl apply -f -
}

# Apply Manifests
apply_manifest "ops/k8s/backend.yaml"
apply_manifest "ops/k8s/frontend.yaml"

echo "✅ Backend & Frontend Deployed!"
echo "⚠️  Note: Frontend API URL is set manually in Phase 4. Update it after LoadBalancer creation if needed."
