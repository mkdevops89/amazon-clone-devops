# Phase 0: App Layer & Traffic Runbook (AWS Console)

**Objective:** Deploy the Backend and Frontend using Auto Scaling Groups (ASG) and expose them via an Application Load Balancer (ALB).

## Prerequisites
*   [x] Network Configured (VPC, Subnets, NAT).
*   [x] Security Groups Created.
*   [x] Data Layer Launched (You MUST have the **Private IPs** of MySQL, Redis, and RabbitMQ).

---

## 🎯 1. Target Groups (TG)
We need two "buckets" for our instances.

### TG 1: Backend
*   **Name:** `tg-backend`
*   **Target Type:** Instances
*   **Protocol:** HTTP | **Port:** 8080
*   **VPC:** `amazon-vpc-manual`
*   **Health Check:** `/api/products` (CRITICAL: `/api/health` does not exist in Phase 0 code. Use `/api/products` which returns 200 OK).

### TG 2: Frontend
*   **Name:** `tg-frontend`
*   **Target Type:** Instances
*   **Protocol:** HTTP | **Port:** 3000
*   **VPC:** `amazon-vpc-manual`
*   **Health Check:** `/`

*(Skip "Register Targets" step for now, ASG will do it automatically).*

---

## 🚀 2. Launch Templates (LT)
Defines "What" to launch.

### LT 1: Backend
*   **Name:** `lt-backend`
*   **AMI:** Amazon Linux 2023
*   **Instance Type:** `t3.medium` (Java needs RAM)
*   **Key Pair:** (Optional, create one if you want SSH access)
*   **Network Settings:**
    *   **Subnet:** Don't include in template (ASG will decide).
    *   **Security Group:** `sg-app`
*   **Advanced Details -> User Data:**
    *   Open `ops/scripts/phase_0/install_backend.sh`
    *   **CRITICAL:** Replace `<REPLACE_WITH_DB_PRIVATE_IP>`, `<...REDIS...>`, `<...MQ...>` with the actual IPs you wrote down.
    *   Paste the edited script.

### LT 2: Frontend
*   **Name:** `lt-frontend`
*   **AMI:** Amazon Linux 2023
*   **Instance Type:** `t3.small`
*   **Security Group:** `sg-app`
*   **Advanced Details -> User Data:**
    *   Open `ops/scripts/phase_0/install_frontend.sh`
    *   **CRITICAL:** Replace `<REPLACE_WITH_BACKEND_PRIVATE_IP>` with... wait! We don't have a static Backend IP because it's in an ASG!
    *   **STOP:** For Phase 0 Manual Mode, to keep it simple, we will point the Frontend to the **ALB DNS Name** (which doesn't exist yet) or use an internal DNS approach.
    *   **Solution for Learning:** We will CREATE the ALB first (Step 3), getting its DNS name, THEN create the Frontend LT.

---

## ⚖️ 3. Application Load Balancer (ALB)
*   **Name:** `amazon-alb`
*   **Scheme:** Internet-facing
*   **Network:** `amazon-vpc-manual`
*   **Subnets:** Select BOTH `public-subnet-1` and `public-subnet-2`.
*   **Security Group:** `sg-alb`
*   **Listeners:**
    *   **HTTP:80** -> Default Action: Forward to `tg-frontend`.
    *   **Add Rule:** If Path is `/api/*` OR `/products*` -> Forward to `tg-backend`.

**Action:** Once created, copy the **DNS Name** (e.g., `amazon-alb-123.us-east-1.elb.amazonaws.com`).

---

## 🚀 4. Finish Frontend LT & ASGs

### Back to "LT 2: Frontend"
*   **User Data:** Open `install_frontend.sh`.
*   Replace `<REPLACE_WITH_BACKEND_PRIVATE_IP>` with the **ALB DNS Name** (e.g., `http://amazon-alb-123....elb.amazonaws.com`).
    *   *Note: Normally we use internal DNS, but for this "Hard Way" runbook, hairpinning via ALB is easiest to visualize.*
*   Create Template.

### Create Auto Scaling Groups
#### ASG 1: Backend
*   **Name:** `asg-backend`
*   **Launch Template:** `lt-backend`
*   **VPC:** `amazon-vpc-manual`
*   **Subnets:** `private-subnet-1`, `private-subnet-2`
*   **Load Balancing:**
    *   Select **"Attach to an existing load balancer"**.
    *   **"Choose from your load balancer target groups"**.
    *   Select **Existing Load Balancer Target Group** -> `tg-backend`.
*   **Group Size:** Desired: 1, Min: 1, Max: 2.
    *   **Health Check Grace Period:** **300 seconds** (CRITICAL: Java takes time to start. Default 300s prevents premature termination).

#### ASG 2: Frontend
*   **Name:** `asg-frontend`
*   **Launch Template:** `lt-frontend`
*   **VPC:** `amazon-vpc-manual`
*   **Subnets:** `private-subnet-1`, `private-subnet-2`
*   **Load Balancing:**
    *   Select **"Attach to an existing load balancer"**.
    *   **"Choose from your load balancer target groups"**.
    *   Select **Existing Load Balancer Target Group** -> `tg-frontend`.
*   **Group Size:** Desired: 1, Min: 1, Max: 2.

---

## ✅ Verification
1.  Go to **EC2 -> Target Groups**. Wait for targets to be `healthy`.
2.  Open your browser.
3.  Go to the **ALB DNS Name**.
    *   You should see the Frontend.
    *   It should try to fetch products (via the ALB -> Backend -> DB).
