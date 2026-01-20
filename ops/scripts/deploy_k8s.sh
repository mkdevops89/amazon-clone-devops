#!/bin/bash
set -e

# Configuration
export AWS_REGION="us-east-1"
export DOMAIN_NAME="devcloudproject.com"

# Fetch Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Using Account ID: $AWS_ACCOUNT_ID"
echo "🌍 Using Domain: $DOMAIN_NAME"
echo "📍 Using Region: $AWS_REGION"

echo "Applying Kubernetes Manifests with substitution..."

# Function to apply manifest with envsubst
apply_manifest() {
    local file=$1
    echo "📄 Processing $file..."
    # Substitute only defined variables to avoid clearing other ${VAR} syntax in k8s if any
    envsubst '${AWS_ACCOUNT_ID} ${AWS_REGION} ${DOMAIN_NAME}' < "$file" | kubectl apply -f -
}

# Apply Manifests
apply_manifest "ops/k8s/backend.yaml"
apply_manifest "ops/k8s/frontend.yaml"

# Note: Ingress ARN Injection is handled separately by update_ingress_cert.sh
# But we can also handle domain substitution here for ingress
apply_manifest "ops/k8s/ingress.yaml"
apply_manifest "ops/k8s/ingress-grafana.yaml"

echo "✅ Deployment Complete!"
