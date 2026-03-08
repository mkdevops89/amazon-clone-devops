#!/bin/bash
set -e

echo "===================================================="
echo "🚀 INSTALLING AWS NODE TERMINATION HANDLER"
echo "===================================================="

# Add the EKS repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install or upgrade the aws-node-termination-handler
helm upgrade --install aws-node-termination-handler eks/aws-node-termination-handler \
  --namespace kube-system \
  --set enableSpotInterruptionDraining=true \
  --set enableRebalanceMonitoring=true \
  --set enableScheduledEventDraining=true

echo "✅ AWS Node Termination Handler installed successfully!"
