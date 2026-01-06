# Phase 11: Secret Management (HashiCorp Vault)

**Goal**: Delete all passwords from GitHub. Inject them dynamically at runtime.
**Role**: Security Engineer (DevSecOps).

## 🛠 Prerequisites
*   **Kubernetes Cluster**: Running.
*   **Helm**: Installed.
*   **Vault CLI**: `brew install vault`.

## 📝 Concept
1.  **Old Way**: `KUBERNETES_TYPE: secret` (Base64 encoded). Problem: Stored in Etcd, readable if someone gets access.
2.  **New Way**: **Vault Agent Injector**. The pod starts -> Vault "Sidecar" logs in -> Fetches secret -> Writes to file `/vault/secrets/config.json`.

## 📝 Step-by-Step Runbook

### 1. Install Vault (Helm)
We run Vault inside the cluster in "Dev Mode" (Memory only, no seal) for learning.
```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --set "server.dev.enabled=true" --set "injector.enabled=true"
```
*Wait for pods to be ready.*

### 2. Enter the Vault
We need to configure it.
```bash
kubectl exec -it vault-0 -- sh
```

### 3. Enable Key-Value Engine
Inside the pod:
```bash
vault secrets enable -path=internal kv-v2
vault kv put internal/database/config username="dbadmin" password="supersecretpassword"
```

### 4. Enable K8s Auth
We need to tell Vault: "Trust Kubernetes Service Accounts".
```bash
vault auth enable kubernetes
vault write auth/kubernetes/config \
    kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
```

### 5. Create a Policy
Who can read the secret? Only the webapp.
```bash
vault policy write webapp - <<EOF
path "internal/data/database/config" {
  capabilities = ["read"]
}
EOF
```

### 6. Create a Role
Bind the K8s ServiceAccount (`backend`) to the Vault Policy (`webapp`).
```bash
vault write auth/kubernetes/role/webapp \
    bound_service_account_names=backend \
    bound_service_account_namespaces=default \
    policies=webapp \
    ttl=24h
```
*Exit the pod (`exit`).*

### 7. Patch the Deployment
We don't need to change Java code. We just add Annotations to the Deployment YAML.
Edit `ops/helm/templates/deployment.yaml` (or do it via `kubectl edit deployment backend`):
```yaml
template:
  metadata:
    annotations:
      vault.hashicorp.com/agent-inject: "true"
      vault.hashicorp.com/role: "webapp"
      vault.hashicorp.com/agent-inject-secret-config: "internal/data/database/config"
```

### 8. Verification
Restart the backend.
```bash
kubectl rollout restart deployment/backend
```
Exec into the pod and look for the file.
```bash
kubectl exec -it <backend-pod-name> -- cat /vault/secrets/config
# You should see the username/password in JSON format!
```

## 🚀 Troubleshooting
*   **"Permission Denied"**: The Service Account name in K8s must exactly match `bound_service_account_names` in Vault.
