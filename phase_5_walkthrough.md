# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
We also resolved critical connectivity and configuration issues to ensure a production-ready deployment.

---

## 🏗️ Step 1: Provision SSL Certificate (Terraform)
We updated the Terraform configuration to include the ACM module.

1.  **Initialize Terraform:**
    ```bash
    cd ops/terraform/aws
    terraform init
    ```

2.  **Apply Changes:**
    ```bash
    terraform apply
    ```
    *   Terraform creates the Certificate and Validating DNS Records.

---

## ☸️ Step 2: Configure Kubernetes Ingress
We need to tell the AWS Load Balancer to use our new Certificate and properly route traffic.

1.  **Inject Certificate ARN (Automated):**
    Run this script and update `ingress.yaml`:
    ```bash
    cd ../../../  # Go back to root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```

2.  **Deploy Ingress & Bridge:**
    ```bash
    kubectl apply -f ops/k8s/grafana-bridge.yaml
    kubectl apply -f ops/k8s/ingress.yaml
    kubectl apply -f ops/k8s/ingress-grafana.yaml
    ```
    *   **Note:** We aligned both Ingress resources to `group.name="amazon-group"` to share a single ALB.

---

## 🌐 Step 3: Update DNS (Route53)
Point your domains to the **new** Load Balancer Address.

1.  **Get Load Balancer Hostname:**
    ```bash
    kubectl get ingress amazon-ingress
    ```
    *   Copy the `ADDRESS` (e.g., `k8s-amazongroup-....us-east-1.elb.amazonaws.com`).

2.  **Update Route53 (AWS Console):**
    *   **CNAME** Records for `www`, `api`, and `grafana` must point to the new ALB Address.

---

## 🔧 Step 4: Troubleshooting & Fixes (Critical)
We encountered and resolved several blockers during deployment. If the app is "Spinning" or "Status DOWN", check these:

### 1. Security Groups (Connectivity)
*   **Issue:** Backend Pods timed out connecting to Redis/MySQL.
*   **Fix:** We authorized the **Worker Node Security Group** (not just Cluster SG) on the Data Layer.
    *   `aws ec2 authorize-security-group-ingress` for Ports 6379 (Redis), 3306 (MySQL), 5671 (MQ).

### 2. Redis SSL (Encryption)
*   **Issue:** Redis connection hung (Handshake Timeout) because AWS Elasticache enables Transit Encryption by default.
*   **Fix:** Enabled SSL in `ops/k8s/backend.yaml`:
    ```yaml
    - name: SPRING_DATA_REDIS_SSL_ENABLED
      value: "true"
    ```

### 3. Frontend Application Build
*   **Issue:** Frontend stuck "Loading products..." because `NEXT_PUBLIC_API_URL` is baked in at build time.
*   **Fix:** Rebuilt the Docker image with the correct API URL:
    ```bash
    docker build --platform linux/amd64 \
      --build-arg NEXT_PUBLIC_API_URL=https://api.devcloudproject.com \
      -t <ECR_REPO_URL>:latest .
    docker push <ECR_REPO_URL>:latest
    ```
    *   *Note: Used `--platform linux/amd64` to match EKS Node architecture.*

---

## ✅ Step 5: Verify
1.  Open `https://www.devcloudproject.com` (Frontend) -> Redirects to Login.
2.  **Log In** and verify Products List loads.
3.  Open `https://api.devcloudproject.com/actuator/health` -> Returns `{"status":"UP"}`.

---

## 🧹 Step 6: Teardown (Clean Up)
When you are done and want to save costs, follow these steps to remove all resources.

1.  **Delete Kubernetes Resources:**
    ```bash
    # Delete Ingresses (This destroys the ALB)
    kubectl delete -f ops/k8s/ingress.yaml
    kubectl delete -f ops/k8s/ingress-grafana.yaml
    kubectl delete -f ops/k8s/grafana-bridge.yaml
    
    # Delete Application Workloads
    kubectl delete -f ops/k8s/backend.yaml
    kubectl delete -f ops/k8s/frontend.yaml
    ```
    *   *Important:* Delete the Ingress first to ensure the AWS Load Balancer is de-provisioned.

2.  **Destroy Terraform Infrastructure:**
    ```bash
    cd ops/terraform/aws
    terraform destroy
    ```
    *   Type `yes` to confirm.
    *   This removes the EKS Cluster, RDS, ElastiCache, Amazon MQ, VPC, and ACM Certificate.

3.  **Clean Route53 (Manual):**
    *   Go to **AWS Console -> Route53**.
    *   Delete the CNAME records (`www`, `api`, `grafana`) you created manually.

4.  **Security Group Cleanup (Manual):**
    *   The specific ingress rules added via AWS CLI to the Data Layer SGs (for Worker Nodes) might persist if not managed by Terraform.
    *   Ideally, Terraform `destroy` should handle the Groups themselves, but verify in Console if any "orphan" rules remain.
