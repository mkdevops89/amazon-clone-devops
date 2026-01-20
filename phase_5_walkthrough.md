# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
It relies on the **AWS Load Balancer Controller** to bridge Kubernetes Ingress with AWS ALBs.

**IMPROVEMENT:** Refactored to use variables (`${AWS_ACCOUNT_ID}`, `${DOMAIN_NAME}`) instead of hardcoded values.

---

## 🛠️ Prerequisites (Critical)

### 1. Install Load Balancer Controller
```bash
./ops/scripts/install_lb_controller.sh
```

### 2. Set Monitoring Password
Using helm:
```bash
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values ops/k8s/monitoring/prometheus-values.yaml \
  --set grafana.adminPassword="YOUR_SECURE_PASSWORD"
```

---

## 🏗️ Step 1: Provision SSL Certificate (Terraform)
1.  **Initialize & Apply:**
    ```bash
    cd ops/terraform/aws
    terraform init
    terraform apply
    ```

---

## 📦 Step 2: Build Frontend Application
**Crucial Step:** The Frontend is a Next.js application. Configuration is **baked in** at build time.

1.  **Export Variables:**
    ```bash
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    export AWS_REGION="us-east-1"
    export DOMAIN_NAME="devcloudproject.com"
    ```

2.  **Build & Push Docker Image:**
    ```bash
    cd frontend
    
    # Build using variables
    docker build --platform linux/amd64 \
      --build-arg NEXT_PUBLIC_API_URL=https://api.${DOMAIN_NAME} \
      -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/amazon-frontend:latest .
    
    # Push to ECR
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/amazon-frontend:latest
    ```

---

## ☸️ Step 3: Configure Kubernetes Ingress

1.  **Inject Certificate ARN:**
    Run the script to inject your specific ACM Certificate ARN from Terraform:
    ```bash
    cd ../  # Return to root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```

2.  **Deploy Ingress & Bridge (New Script):**
    We created a script to handle variable substitution (`envsubst`) for Domain and Account IDs.
    ```bash
    chmod +x ops/scripts/deploy_k8s.sh
    ./ops/scripts/deploy_k8s.sh
    ```
    *   **What this does:** Replaces `${DOMAIN_NAME}` and `${AWS_ACCOUNT_ID}` in your YAML files and applies them to the cluster.

---

## 🌐 Step 4: Update DNS (Route53)
1.  **Get Load Balancer Hostname:** `kubectl get ingress amazon-ingress`
2.  **Update Route53:** Create CNAME records pointing to the ALB Address.

---

## 🔧 Troubleshooting & Fixes

### 1. Security Groups
*   **Fix:** Authorized Worker Node Security Group on the RDS/Redis SGs to fix Database timeouts.

### 2. Redis SSL
*   **Fix:** Enabled `SPRING_DATA_REDIS_SSL_ENABLED="true"` in `backend.yaml` to match AWS ElastiCache setting.

---

## ✅ Step 5: Verify
1.  Open `https://www.devcloudproject.com`.
2.  **Log In** and verify Products List loads.
3.  Open `https://api.devcloudproject.com/actuator/health` -> `{"status":"UP"}`.

---

## 🧹 Step 6: Detailed Cleanup (Teardown)

### 1. De-provision Load Balancer (CRITICAL)
```bash
kubectl delete -f ops/k8s/ingress.yaml
kubectl delete -f ops/k8s/ingress-grafana.yaml
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

### 4. Manual Cleanup
*   Route53 Records, IAM Policy, CloudWatch Logs.
