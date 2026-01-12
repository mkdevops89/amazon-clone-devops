# Phase 4: Kubernetes Deployment Walkthrough

**Objective:** Deploy the Amazon Clone microservices (Frontend & Backend) onto the EKS Cluster created in Phase 3.

## STEP 1: PREPARATION & ECR PROVISIONING
**Goal:** Create the "Folders" (Repositories) in AWS to store your Docker images.

1.  **Open Terminal** at the project root (`amazon-clone-devops`).
2.  **Navigate to Terraform Directory:**
    ```bash
    cd ops/terraform/aws
    ```
3.  **Provision ECR Repositories:**
    Run Terraform to create the `amazon-backend` and `amazon-frontend` repositories defined in `ecr.tf`.
    ```bash
    terraform apply
    ```
    *(Type `yes` when prompted)*.

4.  **Capture Outputs:**
    Look at the end of the output for these two values. **Copy them somewhere** (Notepad/Notes), you will need them!
    *   `ecr_backend_url` (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/amazon-backend`)
    *   `ecr_frontend_url` (e.g., `123456789012.dkr.ecr.us-east-1.amazonaws.com/amazon-frontend`)

5.  **Update Local Kubeconfig:**
    Connect your `kubectl` to the new cluster.
    ```bash
    aws eks update-kubeconfig --region us-east-1 --name amazon-cluster
    ```

---

## STEP 2: BUILD & PUSH DOCKER IMAGES
**Goal:** Package your code and upload it to AWS.

### 2.1 Authenticate Docker
Still in your terminal (any directory), log your local Docker client into AWS ECR.
*Replace `us-east-1` if using a different region.*
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```
*Tip: The registry URL is the first part of your verify ECR URL (before the `/`).*

### 2.2 Build & Push Backend
1.  **Return to Project Root:**
    ```bash
    cd ../../..
    # Verify: 'ls' should show 'backend' and 'frontend' folders.
    ```
2.  **Build Image:**
    ```bash
    docker build -t amazon-backend ./backend
    ```
3.  **Tag Image:**
    *Replace `<ECR_BACKEND_URL>` with the value from Step 1.*
    ```bash
    docker tag amazon-backend:latest <ECR_BACKEND_URL>:latest
    ```
4.  **Push Image:**
    ```bash
    docker push <ECR_BACKEND_URL>:latest
    ```

### 2.3 Build & Push Frontend
1.  **Retrieve Backend LoadBalancer URL:**
    If you haven't deployed the backend yet, you might need to do this later.
    If you HAVE deployed the backend (Step 4), run `kubectl get svc amazon-backend` to get the URL.

2.  **Build Image (With Backend URL):**
    *Replace `<BACKEND_URL>` with your actual backend LB URL (e.g., `http://...elb.amazonaws.com:8080`).*
    ```bash
    docker build \
      --build-arg NEXT_PUBLIC_API_URL=<BACKEND_URL> \
      -t amazon-frontend ./frontend
    ```
2.  **Tag Image:**
    *Replace `<ECR_FRONTEND_URL>` with the value from Step 1.*
    ```bash
    docker tag amazon-frontend:latest <ECR_FRONTEND_URL>:latest
    ```
3.  **Push Image:**
    ```bash
    docker push <ECR_FRONTEND_URL>:latest
    ```

---

## STEP 3: CREATE KUBERNETES MANIFESTS
**Goal:** Tell Kubernetes how to run your containers.

1.  **Navigate to K8s Directory:**
    ```bash
    cd ops/terraform/aws
    # Wait! We need a place for YAMLs. Let's create a 'k8s' folder in 'ops/'.
    cd ../../
    mkdir -p k8s
    cd k8s
    ```
2.  **Create YAML Files:**
    You will create:
    *   `db-secrets.yaml` (Database Passwords)
    *   `backend.yaml` (Deployment + Service)
    *   `frontend.yaml` (Deployment + Service)
    *(We will provide the content for these files in the next interaction).*

---

## STEP 4: DEPLOY TO EKS
**Goal:** Launch the application.

1.  **Inject Secrets Automatically:**
    We have created a script to read Terraform outputs and AWS Secrets Manager, then update `db-secrets.yaml` for you.
    ```bash
    # Make sure you are in the project root
    chmod +x ops/scripts/update_k8s_secrets.sh
    ./ops/scripts/update_k8s_secrets.sh
    ```
    *   **Verify:** Check `ops/k8s/db-secrets.yaml` to see the values filled in.

2.  **Apply Secrets:**
    ```bash
    kubectl apply -f ops/k8s/db-secrets.yaml
    ```
2.  **Apply Backend:**
    ```bash
    kubectl apply -f backend.yaml
    ```
3.  **Apply Frontend:**
    ```bash
    kubectl apply -f frontend.yaml
    ```

---

## STEP 5: VERIFICATION
**Goal:** Confirm it works.

1.  **Check Pods:**
    ```bash
    kubectl get pods
    # Wait until STATUS is 'Running' for all.
    ```
2.  **Get Public URL:**
    ```bash
    kubectl get svc amazon-frontend
    # Copy the EXTERNAL-IP (it looks like a long AWS URL).
    ```
3.  **Visit in Browser:**
    Open the External IP in Chrome/Safari. You should see your Amazon Clone!

## 7. Troubleshooting

### Issue: Backend Crashes with "Access Denied"
*   **Cause:** The password in `db-secrets.yaml` does not match the RDS instance.
*   **Solution:** Retrieve the actual password from AWS Secrets Manager (`aws secretsmanager get-secret-value`) and update `db-secrets.yaml`.

### Issue: Backend LoadBalancer returns "Empty Response"
*   **Cause:** The EKS Node Security Group does not allow inbound traffic on port 8080.
*   **Solution:** Update `main.tf` to add `ingress_allow_8080` to `node_security_group_additional_rules`.

### Issue: Frontend Stuck on "Loading products..."
*   **Cause:** The Frontend connects to `localhost:8080` because `NEXT_PUBLIC_API_URL` was not set during **Docker Build**.
*   **Solution:** Rebuild the image using `--build-arg NEXT_PUBLIC_API_URL=...` (See Step 2.3).

---

## STEP 6: TEARDOWN (CLEANUP)
**Goal:** Delete resources to stop billing.

### Option A: Clean up Application Only (Keep Cluster)
If you want to keep the infrastructure but remove the running apps:
```bash
kubectl delete -f frontend.yaml
kubectl delete -f backend.yaml
kubectl delete -f db-secrets.yaml
```

### Option B: Nuke Everything (Full Destroy)
If you are done for the day and want to delete **everything** (Cluster, VPC, DB, ECR, etc.):

1.  **Delete Images first:** (Terraform cannot delete non-empty ECR repos by default)
    ```bash
    # Empty the repositories manually in AWS Console OR run:
    aws ecr batch-delete-image --repository-name amazon-backend --image-ids imageTag=latest --region us-east-1
    aws ecr batch-delete-image --repository-name amazon-frontend --image-ids imageTag=latest --region us-east-1
    ```
2.  **Run Terraform Destroy:**
    ```bash
    cd ops/terraform/aws
    terraform destroy
    ```
    *(Type `yes` when prompted)*.
