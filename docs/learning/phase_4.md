# Phase 4: Helm Charts (Package Management)

**Goal**: Stop copy-pasting Kubernetes YAML files. "Templatize" them.
**Role**: Release Engineer.

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Detailed in Phase 3 or Minikube.
*   **Helm**: `brew install helm`.

## 📝 Step-by-Step Runbook

### 1. The "Vanilla K8s" Problem
Look at `ops/k8s/backend-deployment.yaml`.
It has hardcoded values: `replicas: 1` and `image: backend:latest`.
If you want 3 replicas in Prod and 1 in Dev, you need two files. That's bad.

### 2. Create a Chart
We already created one in `ops/helm`. Let's inspect it.
```bash
ls ops/helm
# Chart.yaml   -> Metadata (Name, Version)
# values.yaml  -> Default Configuration
# templates/   -> The Logic (deployment.yaml with {{ .Values.replicaCount }})
```

### 3. Lint (Syntax Check)
Before deploying, check for errors.
```bash
helm lint ops/helm
# Expected: "1 chart(s) linted, 0 chart(s) failed"
```

### 4. Dry Run (Debug)
See what YAML Helm will generate without actually installing it.
```bash
helm install --debug --dry-run my-release ops/helm
```
*Scroll up and verify that `replicas` matches what is in `values.yaml`.*

### 5. Install (Deploy)
```bash
helm install amazon-shop ops/helm
# "amazon-shop" is the Release Name.
```

### 6. Upgrade (Change Configuration)
Let's scale up without editing code.
```bash
# Change replicaCount=3 on the fly
helm upgrade amazon-shop ops/helm --set replicaCount=3
```

### 7. Validation
```bash
kubectl get pods
# You should see 3 backend pods terminating/creating.
helm list
# Shows "amazon-shop" revision 2.
```

### 8. Cleanup
```bash
helm uninstall amazon-shop
```

## 🚀 Troubleshooting
*   **"Error: cannot re-use a name that is still in use"**: You forgot to uninstall. Use `helm upgrade` instead of `helm install`.
*   **"CrashLoopBackOff"**: The Pod started, but the app crashed. Check logs: `kubectl logs <pod-name>`. Usually DB connection failed.
