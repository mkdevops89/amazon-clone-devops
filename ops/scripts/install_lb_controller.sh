#!/bin/bash
set -e

CLUSTER_NAME="amazon-cluster"
REGION="us-east-1"
POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"

echo "🔍 Verifying eksctl..."
if ! command -v eksctl &> /dev/null; then
  echo "❌ eksctl is not installed. Please run 'brew install eksctl' first."
  exit 1
fi

echo "🔍 Associating IAM OIDC Provider..."
eksctl utils associate-iam-oidc-provider \
    --region $REGION \
    --cluster $CLUSTER_NAME \
    --approve || echo "OIDC already associated (ignoring error)"

echo "📥 Downloading IAM Policy..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

echo "🛡️ Creating IAM Policy..."
POLICY_ARN=$(aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://iam_policy.json \
    --query 'Policy.Arn' --output text 2>/dev/null) || \
    POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)

echo "✅ Policy ARN: $POLICY_ARN"

echo "👤 Creating ServiceAccount..."
echo "👤 Creating ServiceAccount..."
# Attempt 1: Create (with override)
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name "AmazonEKSLoadBalancerControllerRole" \
  --attach-policy-arn=$POLICY_ARN \
  --approve \
  --override-existing-serviceaccounts

# Self-Healing Check: Verify K8s SA exists. If not, eksctl skipped it due to IAM state drift.
echo "🔍 verifying ServiceAccount existence..."
if ! kubectl get sa aws-load-balancer-controller -n kube-system &> /dev/null; then
  echo "⚠️  ServiceAccount missing! Cleaning up drifted IAM stack and retrying..."
  eksctl delete iamserviceaccount --cluster $CLUSTER_NAME --name aws-load-balancer-controller --namespace kube-system
  
  echo "♻️  Retry: Creating ServiceAccount (Fresh)..."
  eksctl create iamserviceaccount \
    --cluster=$CLUSTER_NAME \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --role-name "AmazonEKSLoadBalancerControllerRole" \
    --attach-policy-arn=$POLICY_ARN \
    --approve
fi

echo "📦 Installing Helm Chart..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 

echo "🎉 Installation Complete! Ingress should work in 1-2 minutes."
