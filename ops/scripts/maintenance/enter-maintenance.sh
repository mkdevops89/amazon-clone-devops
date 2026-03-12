#!/bin/bash
set -euo pipefail

echo "🚨 [$(date +'%Y-%m-%dT%H:%M:%S%z')] Entering Maintenance Mode..."

# 1. Suspend ArgoCD Auto-Sync
# CRITICAL GITOPS REQUIREMENT: If we manually scale down deployments without pausing ArgoCD,
# ArgoCD's "selfHeal" controller will immediately detect the drift and scale the pods back up!
echo "=> 1. Suspending ArgoCD GitOps Auto-Sync (Self-Heal)..."
kubectl patch application amazon-app -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'

# 2. Scale down application pods to halt database traffic
echo "=> 2. Displaying resources targeted for termination..."
kubectl get pods -n devsecops -l "app.kubernetes.io/name in (amazon-frontend, amazon-backend)"

echo ""
echo "=> 3. Scaling down backend and frontend deployments to 0..."
kubectl scale deployment amazon-frontend --replicas=0 -n devsecops
kubectl scale deployment amazon-backend --replicas=0 -n devsecops

echo ""
echo "✅ Maintenance Mode Active."
echo "The application layer is completely offline and safe for database modifications."
echo "Monitoring tools (Grafana & Prometheus) remain operational."
