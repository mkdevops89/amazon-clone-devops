#!/bin/bash
set -e

# Configuration
export AWS_REGION="us-east-1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../../"

echo "===================================================="
echo "🚀 PHASE 4: AUTO-DEPLOYMENT & WIRING SCRIPT"
echo "===================================================="

# 1. Fetch Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Using AWS Account ID: $AWS_ACCOUNT_ID"

# 2. Deploy Backend
echo ""
echo "----------------------------------------------------"
echo "🛠️  Step 1: Deploying Backend Infrastructure..."
echo "----------------------------------------------------"
# Update Backend Manifest with Account ID
envsubst '${AWS_ACCOUNT_ID}' < "$ROOT_DIR/ops/k8s/backend.yaml" | kubectl apply -f -

# 3. Wait for LoadBalancer
echo ""
echo "⏳ Waiting for Backend LoadBalancer to be assigned..."
LB_HOSTNAME=""
ATTEMPTS=0
MAX_ATTEMPTS=40 # 200 seconds

while [ -z "$LB_HOSTNAME" ] || [ "$LB_HOSTNAME" == "<pending>" ]; do
    LB_HOSTNAME=$(kubectl get svc amazon-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -z "$LB_HOSTNAME" ]; then
        LB_HOSTNAME=$(kubectl get svc amazon-backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    fi

    if [ -z "$LB_HOSTNAME" ] || [ "$LB_HOSTNAME" == "<pending>" ]; then
        ATTEMPTS=$((ATTEMPTS+1))
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "❌ Timeout waiting for Backend LoadBalancer!"
            exit 1
        fi
        echo -ne "   Waiting... ($ATTEMPTS/$MAX_ATTEMPTS)\r"
        sleep 5
    fi
done

BACKEND_URL="http://$LB_HOSTNAME:8080"
echo -e "\n✅ Backend is Online at: $BACKEND_URL"

# 4. Rebuild Frontend with Correct URL
echo ""
echo "----------------------------------------------------"
echo "🏗️  Step 2: Building Frontend Image with Backend URL"
echo "----------------------------------------------------"
echo "Reason: Next.js Client-Side code needs the URL baked in at build time."
echo "👉 Baking in: NEXT_PUBLIC_API_URL=$BACKEND_URL"

cd "$ROOT_DIR/frontend"

# Build with platform flag for EKS compatibility
docker build \
  --platform linux/amd64 \
  --build-arg NEXT_PUBLIC_API_URL="$BACKEND_URL" \
  -t "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest" .

# Push
echo "⬆️  Pushing Frontend Image to ECR..."
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest"

# 5. Deploy Frontend
echo ""
echo "----------------------------------------------------"
echo "🚀 Step 3: Deploying Frontend Infrastructure..."
echo "----------------------------------------------------"
cd "$ROOT_DIR"
# Force a redeploy by patching the deployment date (optional) or just re-applying. 
# Re-applying is enough since we pushed :latest, but we must delete/restart pods to pull new image.

# Inject Variables into Manifest
export BACKEND_LOADBALANCER_URL=$LB_HOSTNAME
envsubst '${AWS_ACCOUNT_ID}' < ops/k8s/frontend.yaml | \
sed "s|<BACKEND_LOADBALANCER_URL>|$LB_HOSTNAME|g" | \
kubectl apply -f -

# Restart Pods to ensure they pull the new image we just pushed
echo "🔄 Restarting Frontend Pods to pick up new image..."
kubectl rollout restart deployment/amazon-frontend

echo ""
echo "===================================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "🌍 Access your App here: http://$(kubectl get svc amazon-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "===================================================="
