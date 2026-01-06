# Phase 7: GitOps (ArgoCD)

**Goal**: Deployment should happen when you `git push` (Git as Single Source of Truth).
**Role**: DevOps Engineer.

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running.
*   **Helm**: Installed.

## 📝 Step-by-Step Runbook

### 1. Install ArgoCD
We install it into its own namespace.
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Access the UI
ArgoCD runs inside the cluster. We need to port-forward to see it.
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Ignore SSL warning.
```

### 3. Get Password
The default user is `admin`. The password is in a secret.
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
# Copy this password.
```

### 4. Create an Application
Tell ArgoCD to look at *your* Git Repo.
```bash
kubectl apply -f ops/argocd/application.yaml
```
*Note: Ensure `ops/argocd/application.yaml` points to your GitHub URL, not mine.*

### 5. Verify Sync
1.  Go to the UI.
2.  Click the "Amazon-Like-App" card.
3.  Click **Sync**.
4.  Watch the hearts turn Green (Healthy).

### 6. The "GitOps Flow" (Test)
1.  Edit `ops/helm/values.yaml` locally. Change `replicaCount: 1` to `replicaCount: 3`.
2.  Commit and Push to GitHub.
3.  Click **Refresh** in ArgoCD.
4.  It detects "Out of Sync" (Yellow).
5.  Click **Sync**.
6.  It creates new pods. **This is GitOps.**

## 🚀 Troubleshooting
*   **"Target repo not found"**: Your `application.yaml` has a private repo URL but you didn't configure credentials. For this demo, make the repo Public.
*   **"Sync Failed"**: Kubernetes rejected the YAML. Check the "Events" tab in ArgoCD.

## 🚀 Next Level
ArgoCD handles deployment, but how do you handle traffic?
Go to **[Phase 13: Service Mesh (Istio)](./phase_13.md)** to learn about Canary Deployments.
