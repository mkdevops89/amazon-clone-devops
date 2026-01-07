# ✅ Project Test & Verification Plan

Use this document to strict validate the completion of each phase. **Do not move to the next phase until all tests pass.**

---

## 🟢 Phase 1 & 2: Local & Docker Verification
**Scope:** Validating the Source Code, Docker Containers, and Application Logic.

### 🧪 1. Infrastructure Checks
| Check | Command | Expected Output |
| :--- | :--- | :--- |
| **Containers Running** | `docker-compose ps` | All services (`frontend`, `backend`, `mysql`, `redis`, `rabbitmq`) state is `Up (healthy)`. |
| **Backend Logs** | `docker logs amazon-backend --tail 50` | `Started BackendApplication in X.XXX seconds` (No Stack Traces). |
| **Frontend Logs** | `docker logs amazon-frontend --tail 50` | `Ready in Xms` and listening on port 3000. |

### 🧪 2. Backend API Tests (Curl)
Run these from your local machine (using the Public IP).

**A. Health Check (Security Verification)**
```bash
# Public Health Check -> SHOULD WORK
curl -I http://<PUBLIC-IP>:8080/actuator/health
# Expect: HTTP/1.1 200 OK

# Sensitive Endpoint -> SHOULD BE BLOCKED
curl -I http://<PUBLIC-IP>:8080/actuator/env
# Expect: HTTP/1.1 403 Forbidden
```

**B. Product Catalog**
```bash
# Get all products
curl http://<PUBLIC-IP>:8080/api/products
# Expect JSON with exact items:
# 1. "Wireless Headphones"
# 2. "Smart Watch"
# 3. "Running Shoes"
```

**C. Shopping Cart (Redis)**
```bash
# Add "Wireless Headphones" (ID: 1) to cart
curl -X POST -H "Content-Type: application/json" \
  -d '{"productId":1, "productName":"Wireless Headphones", "price":299.99, "quantity":1}' \
  http://<PUBLIC-IP>:8080/api/cart/testuser

# Verify item is in Redis
curl http://<PUBLIC-IP>:8080/api/cart/testuser
# Expect: [{"productName":"Wireless Headphones"}]
```

### 🧪 3. Frontend UI Tests
1.  **Access:** Open `http://<PUBLIC-IP>:3000`.
2.  **Redirect:** Confirm you are redirected to `/login`.
3.  **Login:** Click "Login" (Mock auth redirects to `/home`).
4.  **Visual Verification (Critical):**
    *   Confirm **3 Product Cards** appear.
    *   Confirm **Images** are visible (Headphones, Watch, Shoes) - *Not placeholders*.
    *   Confirm "Add to Cart" button is clickable.

---

## 🟠 Phase 3: Infrastructure as Code (Terraform)
**Scope:** Validating AWS Cloud Resources.

### 🧪 1. Plan & Apply
```bash
# Verify no destructive changes
terraform plan
# Apply infrastructure
terraform apply -auto-approve
```

### 🧪 2. AWS Console Verification
1.  **VPC:** Check a new VPC exists with correct CIDR (`10.0.0.0/16`).
2.  **EKS:** Check Cluster status is `ACTIVE`.
3.  **RDS:** Check MySQL instance status is `Available`.
4.  **Internet:** Launch a test EC2 in "Public Subnet", SSH in, and ping `google.com`.

---

## 🟣 Phase 4: CI/CD Pipeline
**Scope:** Automation validation.

### 🧪 1. Build Trigger
1.  Make a small change to `README.md`.
2.  `git commit` and `git push`.
3.  **Result:** Jenkins/GitHub Actions should automatically start a new build job.

### 🧪 2. Artifact Upload
1.  Check Nexus/ECR.
2.  **Verify:** A new Docker image tag (e.g., `v1.0.5-<commit_hash>`) exists.

---

## ☸️ Phase 5: Kubernetes & GitOps
**Scope:** Production Deployment.

### 🧪 1. Deployment Status
```bash
kubectl get pods -n amazon-app
# Expect: All pods Running (2/2)
```

### 🧪 2. Service Access
```bash
kubectl get svc -n amazon-app
# Expect: External-IP (LoadBalancer) is provisioned.
# Curl that IP:
curl http://<LoadBalancer-IP>:80
```

### 🧪 3. Self-Healing (GitOps Test)
1.  **Break it:** Manually delete a deployment: `kubectl delete deploy amazon-backend -n amazon-app`.
2.  **Watch:** Wait 2 minutes.
3.  **Verify:** ArgoCD should detect "Out of Sync" and automatically restore the deployment.
