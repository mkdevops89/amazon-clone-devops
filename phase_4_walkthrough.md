# Phase 4: Kubernetes & EKS Deployment ☸️

This phase moves your application from Docker Compose to **AWS EKS** (Elastic Kubernetes Service).

---

## 🛠️ Prerequisites
1.  **AWS CLI** configured.
2.  **Terraform** installed.
3.  **Kubectl** installed.
4.  **Docker** running.

---

## 🏗️ Step 1: Infrastructure (Terraform)
We use Terraform to provision the VPC, EKS Cluster, RDS, Redis, and MQ.

### 1. Initialize S3 Backend (Scripted)
Instead of manual setup, run this script to create the S3 Bucket, DynamoDB Table, and generate `backend.tf`:
```bash
chmod +x ops/scripts/setup_tf_state.sh
./ops/scripts/setup_tf_state.sh
```
*   *Verification:* Check `ops/terraform/aws/backend.tf` to see your new configuration.

### 2. Apply Infrastructure
Now that the backend is configured, deploy the resources:
```bash
cd ops/terraform/aws
terraform init
terraform apply
# Type 'yes' to confirm
```
3.  **Configure Kubectl:**
    Connect your local `kubectl` to the new EKS cluster.
    ```bash
    aws eks update-kubeconfig --region us-east-1 --name amazon-cluster
    # Should show "Ready" nodes
    ```

---

## 🔐 Step 2: Configure Secrets
We need to fetch the Database passwords (from Terraform/Secrets Manager) and inject them into Kubernetes.

1.  **Run Secrets Script:**
    This script reads Terraform outputs and creates `ops/k8s/db-secrets.yaml`.
    ```bash
    cd ../../../ # Go to project root if not already there
    chmod +x ops/scripts/update_k8s_secrets.sh
    ./ops/scripts/update_k8s_secrets.sh
    ```
2.  **Apply Secrets:**
    ```bash
    kubectl apply -f ops/k8s/db-secrets.yaml
    ```
    *   *Result:* A secret named `db-secrets` is created in your cluster.

---

## 📦 Step 3: Build & Push Images
We need to push your code to **AWS ECR**.

1.  **Login to ECR:**
    ```bash
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 406312601212.dkr.ecr.us-east-1.amazonaws.com
    ```
2.  **Export Account ID:**
    ```bash
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ```
3.  **Build & Push (Backend):**
    ```bash
    cd ../../../backend # Go to root/backend
    mvn clean package -DskipTests
    docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest .
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest
    ```
4.  **Build & Push (Frontend):**
    *Note: In Phase 4, we don't have a Domain yet. The Frontend will try to reach the Backend via `localhost` or a placeholder. We will update this after deployment if needed.*
    ```bash
    cd ../frontend
    docker build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest .
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest
    ```

---

## 🚀 Step 4: Deploy to Kubernetes
**CRITICAL:** Do NOT use `kubectl apply -f ...` manually.
We have parameterized the manifests to use your Account ID. Use the script:

1.  **Run Deployment Script:**
    ```bash
    cd ../ # Go to project root
    chmod +x ops/scripts/deploy_k8s.sh
    ./ops/scripts/deploy_k8s.sh
    ```
    *   *Result:* This replaces `${AWS_ACCOUNT_ID}` in your YAMLs and deploys them.

---

## 🔍 Step 5: Verification
1.  **Check Pods:**
    ```bash
    kubectl get pods
    # Status should be 'Running'
    ```
2.  **Get Load Balancer URL:**
    ```bash
    kubectl get svc amazon-frontend
    ```
    *   Copy the `EXTERNAL-IP` (it looks like `a1b2c...us-east-1.elb.amazonaws.com`).
3.  **Test:** Open that URL in your browser.

---

## 🧹 Cleanup
```bash
kubectl delete deployment amazon-backend amazon-frontend
kubectl delete service amazon-backend amazon-frontend
cd ops/terraform/aws
terraform destroy
```
