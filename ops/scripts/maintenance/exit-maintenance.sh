#!/bin/bash
set -euo pipefail

echo "🟢 [$(date +'%Y-%m-%dT%H:%M:%S%z')] Exiting Maintenance Mode..."

# 1. Restore ArgoCD Auto-Sync
# Re-enabling automated sync causes ArgoCD to instantly detect the scaled-down deployments,
# read the true state from Git, and automatically scale the pods back up!
echo "=> 1. Restoring ArgoCD GitOps Auto-Sync (Self-Heal)..."
kubectl patch application amazon-app -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'

echo "=> 2. ArgoCD is now synchronizing cluster state..."
echo "⏳ Waiting for ArgoCD to heal application pods..."
kubectl rollout status deployment/amazon-backend -n devsecops
kubectl rollout status deployment/amazon-frontend -n devsecops

echo ""
echo "✅ Maintenance Mode Deactivated. Platform is fully operational."
