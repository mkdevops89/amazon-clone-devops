#!/bin/bash
set -e

# Configuration
export AWS_REGION="us-east-1"
export DOMAIN_NAME="devcloudproject.com"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../../"

echo "===================================================="
echo "🚀 PHASE 5: AUTO-DEPLOYMENT (HTTPS & DOMAINS)"
echo "===================================================="

# 1. Fetch Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Using AWS Account ID: $AWS_ACCOUNT_ID"
echo "🌍 Using Domain: $DOMAIN_NAME"

echo ""
echo "----------------------------------------------------"
echo "🏗️  Step 1: Building Backend Image"
echo "----------------------------------------------------"
cd "$ROOT_DIR/backend"
docker build --platform linux/amd64 -t "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest" .
echo "⬆️  Pushing Backend Image to ECR..."
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest"

echo ""
echo "----------------------------------------------------"
echo "🏗️  Step 2: Building Frontend Image"
echo "----------------------------------------------------"
echo "Note: In Phase 5, we use a deterministic domain ($DOMAIN_NAME)"
echo "so we can build the frontend immediately without waiting for a LoadBalancer."
echo "👉 Baking in: NEXT_PUBLIC_API_URL=https://api.$DOMAIN_NAME"

cd "$ROOT_DIR/frontend"

# Build with platform flag for EKS compatibility
docker build \
  --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_API_URL="https://api.$DOMAIN_NAME" \
  -t "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest" .

# Push
echo "⬆️  Pushing Frontend Image to ECR..."
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest"

# 3. Deploy Manifests
echo ""
echo "----------------------------------------------------"
echo "----------------------------------------------------"
echo "🚀 Step 3: Deploying Infrastructure..."
echo "----------------------------------------------------"
cd "$ROOT_DIR"

# Apply Manifests with Substitution
apply_manifest() {
    local file=$1
    echo "📄 Processing $file..."
    # Substitute Account ID, Region, and Domain
    envsubst '${AWS_ACCOUNT_ID} ${AWS_REGION} ${DOMAIN_NAME}' < "$file" | kubectl apply -f -
}

apply_manifest "ops/k8s/backend.yaml"
apply_manifest "ops/k8s/frontend.yaml"
apply_manifest "ops/k8s/ingress.yaml"
apply_manifest "ops/k8s/ingress-grafana.yaml"

# Restart Pods to ensure they pull the new image
echo "🔄 Restarting Pods to pick up new images..."
kubectl rollout restart deployment/amazon-backend -n devsecops
kubectl rollout restart deployment/amazon-frontend -n devsecops

echo "----------------------------------------------------"
echo "✅ Deployment Complete!"
echo "🌍 Frontend: https://$DOMAIN_NAME"
echo "🌍 Backend: https://api.$DOMAIN_NAME"
echo "----------------------------------------------------"
