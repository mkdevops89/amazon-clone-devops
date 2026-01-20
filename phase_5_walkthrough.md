# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
It relies on the **AWS Load Balancer Controller** (installed in Phase 4.5) to bridge Kubernetes Ingress with AWS ALBs.

**SECURITY NOTE:** All secrets (Passwords, Account IDs) have been replaced with placeholders (`<...>`). You must substitute them during execution.

---

## 🛠️ Prerequisites (Critical)

Before starting, ensure the **AWS Load Balancer Controller** is installed.

### 1. Install Load Balancer Controller
We use a script to automate this setup.
```bash
./ops/scripts/install_lb_controller.sh
```
*   **Permissions:** This script automatically handles the `iam_policy.json` download and association.

### 2. Set Monitoring Password
The `ops/k8s/monitoring/prometheus-values.yaml` file now uses a placeholder for security.
When deploying or upgrading Prometheus, pass the password using `--set`:
```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values ops/k8s/monitoring/prometheus-values.yaml \
  --set grafana.adminPassword="YOUR_SECURE_PASSWORD"
```

---

## 🏗️ Step 1: Provision SSL Certificate (Terraform)
We added the ACM module to Terraform to request a wildcard certificate.

1.  **Initialize & Apply:**
    ```bash
    cd ops/terraform/aws
    terraform init
    terraform apply
    ```

---

## 📦 Step 2: Build Frontend Application
**Crucial Step:** The Frontend is a Next.js application. Configuration is **baked in** at build time.
You must rebuild the image to point to the new HTTPS Domain.

1.  **Export Account ID:**
    ```bash
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ```

2.  **Build & Push Docker Image:**
    ```bash
    cd frontend
    
    # Build for AWS Architecture (amd64) using the Account ID variable
    docker build --platform linux/amd64 \
      --build-arg NEXT_PUBLIC_API_URL=https://api.devcloudproject.com \
      -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest .
    
    # Push to ECR
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest
    ```

---

## ☸️ Step 3: Configure Kubernetes Ingress
Tell the AWS Load Balancer to use our new Certificate.

1.  **Inject Certificate ARN (Automated):**
    The `ingress.yaml` file contains a placeholder (`<INSERT_YOUR_ACM_ARN>`).
    Run this script to fetch the real ARN from Terraform and inject it:
    ```bash
    cd ../  # Return to root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```
    *   *Result:* The script replaces the placeholder with the actual ARN from your Terraform state.

2.  **Deploy Ingress & Bridge:**
    ```bash
    kubectl apply -f ops/k8s/grafana-bridge.yaml
    kubectl apply -f ops/k8s/ingress.yaml
    kubectl apply -f ops/k8s/ingress-grafana.yaml
    ```
    *   **Note:** We aligned both Ingress resources to `group.name="amazon-group"`.

---

## 🌐 Step 4: Update DNS (Route53)
Point your domains to the **new** Load Balancer Address.

1.  **Get Load Balancer Hostname:**
    ```bash
    kubectl get ingress amazon-ingress
    ```
    *   Copy the `ADDRESS` (e.g., `k8s-amazongroup-....us-east-1.elb.amazonaws.com`).

2.  **Update Route53 (AWS Console):**
    *   Create **CNAME** Records for: `www`, `api`, `grafana` -> ALB Address.

---

## 🔧 Troubleshooting & Fixes

### 1. Security Groups (Connectivity)
*   **Issue:** Backend Pods timed out connecting to Redis/MySQL.
*   **Fix:** **Authorized Worker Node Security Group** on the RDS/Redis SGs.

### 2. Redis SSL (Encryption)
*   **Issue:** Redis connection hung (Handshake Timeout).
*   **Fix:** Enabled SSL in `ops/k8s/backend.yaml`: `SPRING_DATA_REDIS_SSL_ENABLED="true"`.

---

## ✅ Step 5: Verify
1.  Open `https://www.devcloudproject.com`.
2.  **Log In** and verify Products List loads.
3.  Open `https://api.devcloudproject.com/actuator/health` -> `{"status":"UP"}`.

---

## 🧹 Step 6: Detailed Cleanup (Teardown)

### 1. De-provision Load Balancer (CRITICAL)
You **must** delete the Ingress first to avoid orphaned ALBs.
```bash
kubectl delete -f ops/k8s/ingress.yaml
kubectl delete -f ops/k8s/ingress-grafana.yaml
# Wait for ALB to be deleted in Console
```

### 2. Uninstall Controller & Apps
```bash
helm uninstall aws-load-balancer-controller -n kube-system
kubectl delete -f ops/k8s/backend.yaml
kubectl delete -f ops/k8s/frontend.yaml
```

### 3. Destroy Infrastructure (Terraform)
```bash
cd ops/terraform/aws
terraform destroy
```

### 4. Manual Cleanup (Leftovers)
*   **Route53:** Delete manual CNAME records.
*   **IAM Policy:** Delete `AWSLoadBalancerControllerIAMPolicy`.
*   **CloudWatch Logs:** Delete `/aws/eks/...` logs.
*   **Security Groups:** Verify no leftover rules block deletion.
