# Phase 4: Kubernetes Deployment Walkthrough

**Objective:** Deploy the Amazon Clone microservices (Frontend & Backend) onto the EKS Cluster created in Phase 3.

## ⚠️ CRITICAL DEPENDENCY ORDER
To avoid the "Loading Products..." error, we must follow this **exact order**:
1.  Provision Infrastructure (Terraform).
2.  Deploy **Backend** first (to get the LoadBalancer URL).
3.  Build **Frontend** (baking in the Backend URL).
4.  Deploy **Frontend**.

---


## STEP 0: PREREQUISITES (CHECK YOUR TOOLS)
Before we build anything, let's make sure your "Toolbox" is ready.

1.  **Open Terminal** and check these commands:
    ```bash
    aws --version
    terraform -v
    docker --version
    kubectl version --client
    ```
    *If any of these fail, please install the tool first.*

2.  **Authenticate with AWS:**
    Get your access keys ready and run:
    ```bash
    aws configure
    # Region: us-east-1
    # Output: json
    ```
    *This gives Terraform permission to build on your behalf.*

    *This gives Terraform permission to build on your behalf.*

---

## STEP 0.5: CONFIGURE REMOTE STATE (S3)
**Goal:** Store Terraform state securely in S3 instead of locally.

**We have a script to automate this!**
It will create your unique S3 Bucket, the DynamoDB Lock Table, and generate the `backend.tf` file for you.

1.  **Run the Setup Script (From Project Root):**
    Ensure you are in the root directory (where `ops/` is visible).
    ```bash
    chmod +x ops/scripts/setup_tf_state.sh
    ./ops/scripts/setup_tf_state.sh
    ```

    *Expected Output:*
    > ✅ Backend infrastructure ready!
    > Bucket: amazon-clone-tfstate-123456789012
    > Table:  amazon-clone-tf-locks
    > File:   .../ops/terraform/aws/backend.tf

2.  **Verify:**
    Check that the file was created:
    ```bash
    cat ops/terraform/aws/backend.tf
    ```

---

## STEP 1: PREPARATION & INFRASTRUCTURE
**Goal:** We need to "Initialize" our project and create the repositories.

1.  **Navigate to Terraform Directory:**
    ```bash
    cd ops/terraform/aws
    ```

2.  **Initialize Terraform:**
    This downloads the AWS plugins needed to run the code.
    ```bash
    terraform init
    ```
    *(You should see a green "Terraform has been successfully initialized!" message).*

3.  **Preview the Plan (Optional but Recommended):**
    See what Terraform is *about* to build. It's like a blueprint check.
    ```bash
    terraform plan
    ```
    *(Scan the output. It should say it plans to add resources).*

4.  **Provision ECR Repositories (Apply):**
    Ready? Let's build the Docker Repositories.
    ```bash
    terraform apply
    ```
    *(Type `yes` when prompted)*.

5.  **Capture Outputs:**
    Look at the end of the output for these two values. **Copy them somewhere** (Notepad/Notes), you will need them!
    *   `ecr_backend_url`
    *   `ecr_frontend_url`

6.  **Update Kubeconfig (Connect to Cluster):**
    Now that we are authenticated, let's tell `kubectl` which cluster to talk to.
    ```bash
    aws eks update-kubeconfig --region us-east-1 --name amazon-cluster
    ```

---

## STEP 2: DEPLOY BACKEND (Database & API)
**Goal:** specific goal. Get the Backend running so we can generate its Public URL.

### 2.1 Authenticate Docker
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### 2.2 Build & Push Backend Environment
1.  **Return to Project Root:** `cd ../../..`
2.  **Build & Push:**
    ```bash
    docker build -t amazon-backend ./backend
    docker tag amazon-backend:latest <ECR_BACKEND_URL>:latest
    docker push <ECR_BACKEND_URL>:latest
    ```

### 2.3 Inject Secrets & Deploy
1.  **Automated Secret Injection:**
    Use our helper script to read Terraform outputs and AWS Secrets Manager (Real Password):
    ```bash
    chmod +x ops/scripts/update_k8s_secrets.sh
    ./ops/scripts/update_k8s_secrets.sh
    ```
    *(Check `ops/k8s/db-secrets.yaml` to confirm it is filled).*

2.  **Deploy to Kubernetes:**
    ```bash
    kubectl apply -f ops/k8s/db-secrets.yaml
    kubectl apply -f ops/k8s/backend.yaml
    ```

3.  **Wait for Backend LoadBalancer:**
    It takes roughly 2-3 minutes for AWS to assign a URL.
    ```bash
    kubectl get svc amazon-backend
    ```
    **COPY the `EXTERNAL-IP`** (e.g., `a846...elb.amazonaws.com`).
    *Note: The script output usually has port 8080.*

---

## STEP 3: DEPLOY FRONTEND (UI)
**Goal:** Build the UI with the *correct* Backend connection.

### 3.1 Build & Push Frontend (Crucial Step)
You **MUST** provide the Backend URL here. If you skip this, the app will fail to load products.

*Replace `<BACKEND_LB_URL>` with the EXTERNAL-IP from Step 2.3 (including port 8080 if applicable, e.g., `http://...:8080`).*

```bash
docker build \
  --build-arg NEXT_PUBLIC_API_URL=http://<BACKEND_LB_URL>:8080 \
  -t amazon-frontend ./frontend
```

**Tag & Push:**
```bash
docker tag amazon-frontend:latest <ECR_FRONTEND_URL>:latest
docker push <ECR_FRONTEND_URL>:latest
```

### 3.2 Deploy Frontend
```bash
kubectl apply -f ops/k8s/frontend.yaml
```

---

## STEP 4: VERIFICATION
**Goal:** Confirm it works.

1.  **Get Public URL:**
    ```bash
    kubectl get svc amazon-frontend
    ```
2.  **Visit in Browser:**
    Open the External IP. You should see your Amazon Clone with **Products Loaded**!

---

## 5. Troubleshooting / Post-Mortem

### Q: "Loading products..." forever?
*   **Cause:** The frontend image was built *without* the `NEXT_PUBLIC_API_URL` or with the wrong one.
*   **Fix:** Re-run Step 3.1 with the correct URL.

### Q: Backend LoadBalancer "Empty Response"?
*   **Cause:** Security Group blocking Port 8080.
*   **Fix:** Ensure your Terraform `main.tf` has the `ingress_allow_8080` rule applying to the **Node Group** (not just the Service). (We fixed this in `phase-4-k8s`).

### Q: "403 Forbidden" or "404 Not Found" on `/products`?
*   **Cause:** Path mismatch. Frontend calls `/products`, Backend expected `/api/products`.
*   **Status:** **FIXED**. We updated `ProductController.java` to accept both paths.

---

## STEP 6: TEARDOWN
If you are done for the day:
```bash
cd ops/terraform/aws
terraform destroy
# (Remember to empty ECR repos via console/script first if destroy fails)
```

