# ✅ Project Test & Verification Plan (Phase 1 & 2)

Use this document to strict validate the completion of Phase 1 (Manual/VM) and Phase 2 (Docker).

---

## 🟢 Phase 1 & 2: Local & Docker Verification
**Scope:** Validating the Source Code, Docker Containers, and Application Logic.

### 🧪 1. Infrastructure Checks
| Check | Command | Expected Output |
| :--- | :--- | :--- |
| **Containers Running** | `docker-compose ps` | All services (`frontend`, `backend`, `mysql`, `redis`, `rabbitmq`, `datadog`) state is `Up (healthy)`. |
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

## � Datadog Observability Verification
**Scope:** Verify that the Datadog Agent is correctly sending data to your Datadog Dashboard.

### 🧪 1. Infrastructure & Containers
1.  **Login to Datadog:** Go to https://app.datadoghq.com/.
2.  **Navigate to:** `Infrastructure` -> `Containers`.
3.  **Verify:** You should see a list of your running containers:
    *   `amazon-backend`
    *   `amazon-frontend`
    *   `amazon-mysql`
    *   `amazon-redis`
    *   `amazon-rabbitmq`

### 🧪 2. Live Logs
1.  **Navigate to:** `Logs` -> `Live Tail` (or `Search`).
2.  **Filter:** Type `service:amazon-backend` in the search bar.
3.  **Action:** Refresh your app website a few times.
4.  **Verify:** You should see new log lines appearing in Datadog (e.g., "Fetching all products").

### 🧪 3. Application Performance Monitoring (APM)
*Note: APM requires the Java Agent/Node Tracer to be active inside the container code. If only Infrastructure monitoring is enabled, skip this.*
1.  **Navigate to:** `APM` -> `Services`.
2.  **Verify:** Look for services named `amazon-backend` or `amazon-frontend`.
3.  **Trace:** Click on a service to see request throughput and latency graphs.

### 🧪 4. Metrics
1.  **Navigate to:** `Metrics` -> `Explorer`.
2.  **Query:** Search for `docker.cpu.usage` or `docker.mem.rss`.
3.  **Verify:** You should see a graph showing resource usage for your containers.
