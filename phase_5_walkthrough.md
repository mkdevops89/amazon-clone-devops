# Phase 5: Domains & HTTPS 🔐

This phase secures your application using **AWS Certificate Manager (ACM)** and **Route53**.
It relies on the **AWS Load Balancer Controller** (installed in Phase 4.5) to bridge Kubernetes Ingress with AWS ALBs.

---

## 🛠️ Prerequisites (Critical)

Before starting, ensure the **AWS Load Balancer Controller** is installed.
This component is responsible for reading your `db-secrets`, `ingress.yaml`, and creating the actual Load Balancer in AWS.

### 1. Install Load Balancer Controller
We use a script to automate this complex setup:
```bash
./ops/scripts/install_lb_controller.sh
```

**What this script does:**
1.  **IAM Policy (`iam_policy.json`):** It downloads the *official* AWS IAM Policy from GitHub (`raw.githubusercontent.com/.../iam_policy.json`). This defines the permissions the controller needs (e.g., `elasticloadbalancing:*`, `acm:*`).
    *   *Note:* You might see `iam_policy.json` in your root directory. This is the downloaded policy file used to create the AWS IAM Role.
2.  **ServiceAccount:** It associates an IAM Role with a Kubernetes ServiceAccount (`aws-load-balancer-controller`) using OIDC.
3.  **Helm Chart:** It installs the controller into the `kube-system` namespace.

---

## 🏗️ Step 1: Provision SSL Certificate (Terraform)
We added the ACM module to Terraform to request a wildcard certificate (`*.devcloudproject.com`).

1.  **Initialize & Apply:**
    ```bash
    cd ops/terraform/aws
    terraform init
    terraform apply
    ```
    *   **Result:** Terraform requests a certificate and creates DNS validation records in Route53.
    *   **Wait:** It may take a few minutes for the status to become `ISSUED`.

---

## 📦 Step 2: Build Frontend Application
**Crucial Step:** The Frontend is a Next.js application. Configuration like the API URL is **baked in** at build time.
We must rebuild the image to point to the new HTTPS Domain.

1.  **Build & Push Docker Image:**
    ```bash
    cd frontend
    
    # Build for AWS Architecture (amd64) with the new API URL
    docker build --platform linux/amd64 \
      --build-arg NEXT_PUBLIC_API_URL=https://api.devcloudproject.com \
      -t 406312601212.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest .
    
    # Push to ECR
    docker push 406312601212.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest
    ```
    *   **Why?** If you skip this, `NEXT_PUBLIC_API_URL` defaults to `localhost`, and the browser will fail to load products.

---

## ☸️ Step 3: Configure Kubernetes Ingress
Tell the AWS Load Balancer to use our new Certificate and properly route traffic.

1.  **Inject Certificate ARN:**
    Run this script and update `ingress.yaml`:
    ```bash
    cd ../  # Return to root
    chmod +x ops/scripts/update_ingress_cert.sh
    ./ops/scripts/update_ingress_cert.sh
    ```

2.  **Deploy Ingress & Bridge:**
    ```bash
    kubectl apply -f ops/k8s/grafana-bridge.yaml
    kubectl apply -f ops/k8s/ingress.yaml
    kubectl apply -f ops/k8s/ingress-grafana.yaml
    ```
    *   **Note:** We aligned both Ingress resources to `group.name="amazon-group"`. This merges them into a single AWS ALB, saving costs and simplifying DNS.

---

## 🌐 Step 4: Update DNS (Route53)
Point your domains to the **new** Load Balancer Address.

1.  **Get Load Balancer Hostname:**
    ```bash
    kubectl get ingress amazon-ingress
    ```
    *   Copy the `ADDRESS` (e.g., `k8s-amazongroup-....us-east-1.elb.amazonaws.com`).

2.  **Update Route53 (AWS Console):**
    *   Create **CNAME** Records for:
        *   `www.devcloudproject.com` -> ALB Address
        *   `api.devcloudproject.com` -> ALB Address
        *   `grafana.devcloudproject.com` -> ALB Address

---

## 🔧 Troubleshooting & Fixes
If the app is "Spinning" or "Status DOWN", check these common issues we resolved:

### 1. Security Groups (Connectivity)
*   **Issue:** Backend Pods timed out connecting to Redis/MySQL.
*   **Reason:** The EKS *Cluster* SG was authorized, but Pods run on *Worker Nodes*.
*   **Fix:** Authorize the **Worker Node Security Group** (`sg-0c19...`) on the RDS/Redis Security Groups.

### 2. Redis SSL (Encryption)
*   **Issue:** Redis connection hung (Handshake Timeout).
*   **Reason:** AWS Elasticache enables Transit Encryption (SSL) by default. Spring Boot defaults to Plaintext.
*   **Fix:** Enabled SSL in `ops/k8s/backend.yaml`: `SPRING_DATA_REDIS_SSL_ENABLED="true"`.

---

## ✅ Step 5: Verify
1.  Open `https://www.devcloudproject.com`.
2.  **Log In** and verify Products List loads (Prices/Images visible).
3.  Open `https://api.devcloudproject.com/actuator/health` -> `{"status":"UP"}`.

---

## 🧹 Step 6: Detailed Cleanup (Teardown)
To completely remove all resources and stop billing, follow this exact order.

### 1. De-provision Load Balancer (CRITICAL)
You **must** delete the Ingress first. If you destroy the cluster while the Ingress exists, the AWS ALB will be orphaned and you will continue to be billed for it.

```bash
# Delete Ingress Resources
kubectl delete -f ops/k8s/ingress.yaml
kubectl delete -f ops/k8s/ingress-grafana.yaml
kubectl delete -f ops/k8s/grafana-bridge.yaml

# Wait for ALB to disappear (Check AWS Console -> EC2 -> Load Balancers)
echo "Waiting for ALB deletion..."
```

### 2. Uninstall Controller & Apps
```bash
# Uninstall LB Controller
helm uninstall aws-load-balancer-controller -n kube-system

# Delete Workloads
kubectl delete -f ops/k8s/backend.yaml
kubectl delete -f ops/k8s/frontend.yaml
```

### 3. Destroy Infrastructure (Terraform)
This removes EKS, RDS, Redis, MQ, VPC, and ACM Certificate.
```bash
cd ops/terraform/aws
terraform destroy
# Type 'yes' to confirm
```

### 4. Manual Cleanup (Leftovers)
Some resources created via scripts or console must be deleted manually:

1.  **Route53 Records:**
    *   Go to Hosted Zone `devcloudproject.com`.
    *   Delete the CNAME records (`www`, `api`, `grafana`) you created manually.
2.  **IAM Policy:**
    *   Go to **IAM -> Policies**.
    *   Search for `AWSLoadBalancerControllerIAMPolicy`.
    *   Delete it. (Created by `install_lb_controller.sh`).
3.  **CloudWatch Logs:**
    *   Go to **CloudWatch -> Log Groups**.
    *   Delete `/aws/eks/amazon-cluster/...` log groups if they exist.
4.  **Security Group Rules:**
    *   Check your RDS/Redis Security Groups.
    *   If `terraform destroy` fails to delete them because of "Dependency Violation" (common if rules refer to deleted groups), manually delete the Inbound Rules permitting traffic from the EKS Worker Nodes.
