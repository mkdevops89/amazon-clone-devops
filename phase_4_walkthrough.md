# Phase 4: Kubernetes & EKS Deployment ☸️

This phase transitions the application from Docker Compose to **AWS EKS** (Elastic Kubernetes Service).

---

## 🛠️ Prerequisites
1.  **AWS CLI** configured (`aws configure`).
2.  **Terraform** installed.
3.  **Kubectl** installed.
4.  **Docker** running.

---

## 🏗️ Step 1: Infrastructure (Terraform)
Provision the VPC, EKS Cluster, RDS, Redis, and MQ using Terraform.

### 1. Initialize S3 Backend (Scripted)
Run the automated setup script to detect your Account ID, create a unique S3 Bucket and DynamoDB Lock Table, and generate the `backend.tf` configuration file:
```bash
chmod +x ops/scripts/setup_tf_state.sh
./ops/scripts/setup_tf_state.sh
```
*   *Verification:* Inspect `ops/terraform/aws/backend.tf` to confirm the configuration.

### 2. Apply Infrastructure
Deploy the infrastructure resources:
```bash
cd ops/terraform/aws
terraform init
terraform apply
# Type 'yes' to confirm when prompted
```

### 3. Configure Kubectl
Connect the local `kubectl` client to the newly created EKS cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name amazon-cluster
```

---

## 🔐 Step 2: Configure Secrets
Fetch the Database passwords (managed by Terraform/Secrets Manager) and inject them into Kubernetes as a Secret.

1.  **Run Secrets Script:**
    Execute the helper script to read Terraform outputs and create the `ops/k8s/db-secrets.yaml` manifest:
    ```bash
    cd ../../../ # Navigate to project root
    chmod +x ops/scripts/update_k8s_secrets.sh
    ./ops/scripts/update_k8s_secrets.sh
    ```
2.  **Apply Secrets:**
    Apply the generated secret to the cluster:
    ```bash
    kubectl apply -f ops/k8s/db-secrets.yaml
    ```
    *   *Result:* A Kubernetes Secret named `db-secrets` is created.

---

## 📦 Step 3: Build & Push Images
Compile the application code and push the Docker images to **AWS ECR**.

1.  **Export Account ID:**
    Export the AWS Account ID to an environment variable for use in subsequent commands:
    ```bash
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ```

2.  **Login to ECR:**
    Authenticate the Docker client with the AWS Elastic Container Registry:
    ```bash
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com
    ```

3.  **Build & Push (Backend):**
    ```bash
    cd ../../../backend # Navigate to root/backend
    mvn clean package -DskipTests
    docker build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest .
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-backend:latest
    ```

4.  **Build & Push (Frontend):**
    ```bash
    cd ../frontend
    docker build --platform linux/amd64 -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest .
    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend:latest
    ```

---

## 🚀 Step 4: Deploy to Kubernetes
**CRITICAL:** Do NOT use `kubectl apply -f ...` manually.

We use a smart deployment script that:
1.  Deploys the Backend.
2.  **Waits** for the Load Balancer to come online.
3.  **Automatically wires** the Backend's URL into the Frontend configuration.
4.  Deploys the Frontend.

1.  **Run Deployment Script:**
    Execute the deployment script to substitute variables and apply the manifests:
    ```bash
    cd ../ # Navigate to project root
    chmod +x ops/scripts/deploy_k8s.sh
    ./ops/scripts/deploy_k8s.sh
    ```
    *   *Result:* The script replaces placeholders with actual values and deploys the resources to the cluster.

---

## 🔍 Step 5: Verification
1.  **Check Pods:**
    Verify that all pods are in the 'Running' state:
    ```bash
    kubectl get pods
    ```

2.  **Get Load Balancer URL:**
    Retrieve the external address of the Frontend service:
    ```bash
    kubectl get svc amazon-frontend
    ```
    *   Copy the `EXTERNAL-IP` (format: `a1b2c...us-east-1.elb.amazonaws.com`).

3.  **Test:**
    Open the copied URL in a web browser to verify the application is accessible.

---

## 🧹 Cleanup
To avoid incurring unnecessary costs, destroy the infrastructure when finished:
```bash
kubectl delete deployment amazon-backend amazon-frontend
kubectl delete service amazon-backend amazon-frontend
cd ops/terraform/aws
terraform destroy
```
