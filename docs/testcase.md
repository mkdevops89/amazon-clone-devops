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
Run these inside the EC2/VM or from your machine if ports are forwarded.

**A. Health Check**
```bash
curl -I http://localhost:8080/actuator/health
# Expect: HTTP/1.1 200 OK
```

**B. Product Catalog**
```bash
# Get all products
curl http://localhost:8080/api/products
# Expect: JSON Array [{"id":1,"name":"Headphones"...}]
```

**C. Shopping Cart (Redis)**
```bash
# Add item to cart
curl -X POST -H "Content-Type: application/json" \
  -d '{"productId":1, "productName":"Test", "price":10.0, "quantity":1}' \
  http://localhost:8080/api/cart/testuser

# Verify item is in Redis
curl http://localhost:8080/api/cart/testuser
# Expect: [{"productName":"Test"}]
```

**D. Order Processing (RabbitMQ)**
```bash
# Place an order
curl -X POST "http://localhost:8080/api/orders/testuser?amount=50.00"

# Verify RabbitMQ Message (Manual Check)
# Go to http://<IP>:15672 (guest/guest) -> Queues -> order-queue
# You should see "Message rates" spike or "Ready" count increase temporarily.
```

### 🧪 3. Frontend UI Tests
1.  **Access:** Open `http://<IP>:3000`.
2.  **Redirect:** Confirm you are redirected to `/login`.
3.  **Images:** Verify product images (Headphones, Watch, Shoes) load correctly (no broken icons).
4.  **Login:** Click "Login". (Since Auth is mocked/permissive, it should redirect you to `/home` or dashboard).

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
