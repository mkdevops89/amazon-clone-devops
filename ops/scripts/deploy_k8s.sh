#!/bin/bash
set -e

# Configuration
export AWS_REGION="us-east-1"

# Fetch Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "🔍 Using Account ID: $AWS_ACCOUNT_ID"

echo "----------------------------------------------------"
echo "🚀 Step 1: Deploying Backend..."
echo "----------------------------------------------------"

# Apply Backend First
envsubst '${AWS_ACCOUNT_ID}' < ops/k8s/backend.yaml | kubectl apply -f -

echo "⏳ Waiting for Backend LoadBalancer to be ready..."
# Wait up to 3 minutes for the LoadBalancer to get an ingress hostname
# We check until 'EXTERNAL-IP' is not '<pending>' or empty
LB_HOSTNAME=""
ATTEMPTS=0
MAX_ATTEMPTS=40

while [ -z "$LB_HOSTNAME" ] || [ "$LB_HOSTNAME" == "<pending>" ]; do
    LB_HOSTNAME=$(kubectl get svc amazon-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -z "$LB_HOSTNAME" ]; then
        # Fallback for AWS which sometimes uses 'hostname', sometimes 'ip' (but AWS uses hostname)
        LB_HOSTNAME=$(kubectl get svc amazon-backend -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    fi

    if [ -z "$LB_HOSTNAME" ] || [ "$LB_HOSTNAME" == "<pending>" ]; do
        ATTEMPTS=$((ATTEMPTS+1))
        if [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; then
            echo "❌ Timeout waiting for Backend LoadBalancer!"
            exit 1
        fi
        echo -ne "   Waiting... ($ATTEMPTS/$MAX_ATTEMPTS)\r"
        sleep 5
    fi
done

echo -e "\n✅ Backend is UP at: $LB_HOSTNAME"
export BACKEND_URL="http://$LB_HOSTNAME:8080"

echo "----------------------------------------------------"
echo "🚀 Step 2: Deploying Frontend..."
echo "----------------------------------------------------"
echo "👉 Injecting Backend URL: $BACKEND_URL"

# Apply Frontend with BOTH substitutions
# We use a temp variable for envsubst to catch both standard variables
export BACKEND_LOADBALANCER_URL=$LB_HOSTNAME

# Note: We replace <BACKEND_LOADBALANCER_URL> literally if envsubst doesn't pick it up, 
# or use envsubst if the YAML uses ${BACKEND_LOADBALANCER_URL}.
# For Phase 4 compatibility, we'll try sed on the stream to catch the specific placeholder.

# 1. Substitute AWS_ACCOUNT_ID
# 2. Substitute <BACKEND_LOADBALANCER_URL> with actual Hostname
envsubst '${AWS_ACCOUNT_ID}' < ops/k8s/frontend.yaml | \
sed "s|<BACKEND_LOADBALANCER_URL>|$LB_HOSTNAME|g" | \
kubectl apply -f -

echo "----------------------------------------------------"
echo "✅ Deployment Complete!"
echo "🌍 Frontend: http://$(kubectl get svc amazon-frontend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "----------------------------------------------------"
