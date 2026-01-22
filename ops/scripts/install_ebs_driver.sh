#!/bin/bash
set -e

# Configuration
CLUSTER_NAME="amazon-cluster"
REGION="us-east-1"
SERVICE_ACCOUNT_NAME="ebs-csi-controller-sa"
ROLE_NAME="AmazonEKS_EBS_CSI_DriverRole"
POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"

echo "🔍 Checking configuration..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "   Account ID: $ACCOUNT_ID"
echo "   Region: $REGION"
echo "   Cluster: $CLUSTER_NAME"

# 1. Create OIDC Provider (Idempotent)
echo "🔗 associating IAM OIDC provider..."
eksctl utils associate-iam-oidc-provider --cluster=$CLUSTER_NAME --approve

# 2. Check if Service Account exists
echo "👤 Checking Service Account for EBS CSI..."
if kubectl get sa -n kube-system $SERVICE_ACCOUNT_NAME >/dev/null 2>&1; then
    echo "✅ Service Account $SERVICE_ACCOUNT_NAME already exists."
else
    echo "🚀 Creating IAM Service Account and Role..."
    eksctl create iamserviceaccount \
      --name $SERVICE_ACCOUNT_NAME \
      --namespace kube-system \
      --cluster $CLUSTER_NAME \
      --attach-policy-arn $POLICY_ARN \
      --approve \
      --role-only \
      --role-name $ROLE_NAME \
      --override-existing-serviceaccounts
    echo "✅ Role created."
fi

# 3. Install/Update Addon
echo "📦 Installing EBS CSI Driver Addon..."
# We use --force to overwrite if it exists in a bad state
eksctl create addon \
    --name aws-ebs-csi-driver \
    --cluster $CLUSTER_NAME \
    --service-account-role-arn "arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}" \
    --force

echo "🎉 EBS CSI Driver installed successfully!"
echo "⏳ Waiting for pods to stabilize..."
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver
