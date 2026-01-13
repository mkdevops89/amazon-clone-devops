# Phase 0: The "Hard Way" Master Walkthrough

**Objective:** Build a highly available, 3-tier architecture on AWS manually using the Console ("ClickOps").
**Goal:** Understand the exact infrastructure components (VPC, Subnets, Security Groups, EC2, ALB, ASG) before automating them with Terraform in Phase 3.

---

## 🏗️ Architecture Overview

We will build:
1.  **Network:** Custom VPC with 2 Public and 2 Private Subnets.
2.  **Security:** Strict Security Groups for minimal access.
3.  **Data Layer:** MySQL, Redis, and RabbitMQ on raw EC2 instances (Stateful) in Private Subnets.
4.  **App Layer:** Spring Boot Backend and Next.js Frontend on EC2 via Auto Scaling Groups (Stateless).
5.  **Traffic:** Application Load Balancer (ALB) to route traffic from the internet.

---

## 📋 Prerequisites

*   AWS Account with Admin access.
*   Region: `us-east-1` (N. Virginia).
*   SSH Key Pair (Optional, for debugging).

---

## 🛠️ Step 1: Network Setup
**Reference:** [Phase 0 Network Config](file:///Users/michael/Documents/amazonlikeapp/phase_0_network_config.md)

1.  **VPC:** Create `amazon-vpc-manual` (`10.0.0.0/16`).
2.  **Subnets:** Create 4 subnets (2 Public, 2 Private) in `us-east-1a` and `us-east-1b`.
3.  **IGW:** Create and attach `amazon-igw-manual`.
4.  **NAT Gateway:** Create `amazon-nat-manual` in `public-subnet-1`.
5.  **Route Tables:**
    *   **Public RT:** Route `0.0.0.0/0` to IGW. Associate with Public Subnets.
    *   **Private RT:** Route `0.0.0.0/0` to NAT GW. Associate with Private Subnets.

---

## 🛡️ Step 2: Security Groups
**Reference:** [Phase 0 Security Runbook](file:///Users/michael/Documents/amazonlikeapp/phase_0_security_runbook.md)

Create them in this exact order to avoid dependency errors:

1.  **`sg-alb`:** Allow HTTP (80) & HTTPS (443) from `0.0.0.0/0`.
2.  **`sg-app`:** Allow Ports 3000 & 8080 from `sg-alb`.
3.  **`sg-data`:** Allow Ports 3306 (MySQL), 6379 (Redis), 5672 (RabbitMQ) from `sg-app`.

---

## 💾 Step 3: Data Layer Deployment
**Reference:** [Phase 0 Data Launch Runbook](file:///Users/michael/Documents/amazonlikeapp/phase_0_data_launch_runbook.md)

Launch 3 separate EC2 instances into **Private Subnets**.

1.  **MySQL:** Use User Data from `ops/scripts/phase_0/install_mysql.sh`.
2.  **Redis:** Use User Data from `ops/scripts/phase_0/install_redis.sh`.
3.  **RabbitMQ:** Use User Data from `ops/scripts/phase_0/install_rabbitmq.sh`.

**🛑 CRITICAL CHECKPOINT:**
After they launch, write down their **Private IPs**. You CANNOT proceed without them.

| Service | Private IP (Write Here) |
| :--- | :--- |
| MySQL | `___________________` |
| Redis | `___________________` |
| RabbitMQ | `___________________` |

---

## 🚀 Step 4: Application Layer Deployment
**Reference:** [Phase 0 App Launch Runbook](file:///Users/michael/Documents/amazonlikeapp/phase_0_app_launch_runbook.md)

### 4.1. Load Balancer (ALB) Setup
Create the ALB *before* the Auto Scaling Groups so we can point the Frontend to it.
1.  Create Target Group `tg-backend` (Port 8080). **Skip "Register Targets" step** (ASG will do it).
2.  Create Target Group `tg-frontend` (Port 3000). **Skip "Register Targets" step** (ASG will do it).
3.  Create ALB `amazon-alb` (Internet Facing, Public Subnets, `sg-alb`).
4.  **Listeners:**
    *   Port 80 -> Default to `tg-frontend`.
    *   Add Rule: Host `api.devcloudproject.com` -> `tg-backend`.
5.  **Copy ALB DNS Name:** (e.g., `amazon-alb-....amazonaws.com`)

### 4.2. Launch Templates & ASGs
1.  **Backend:**
    *   Create Launch Template `lt-backend` using `ops/scripts/phase_0/install_backend.sh`.
    *   **IMPORTANT:** Update the script with the **Data Layer Private IPs**.
    *   Create ASG `asg-backend`: 1 Instance.
    *   **IMPORTANT:** inside ASG Wizard, select **"Attach to an existing load balancer"** -> **"Choose from your load balancer target groups"** -> Select `tg-backend`.
2.  **Frontend:**
    *   Create Launch Template `lt-frontend` using `ops/scripts/phase_0/install_frontend.sh`.
    *   **IMPORTANT:** Update the script replacing `<REPLACE_WITH_BACKEND_PRIVATE_IP>` with the **ALB DNS Name** (http://...).
    *   Create ASG `asg-frontend`: 1 Instance.
    *   **IMPORTANT:** inside ASG Wizard, select **"Attach to an existing load balancer"** -> **"Choose from your load balancer target groups"** -> Select `tg-frontend`.

---

## ✅ Step 5: Verification

1.  **Wait** for ASG instances to register in Target Groups and become `Healthy`.
2.  **Visit the ALB DNS Name** in your browser.
    *   You should see the Amazon Clone Frontend.
    *   It should successfully fetch products from the Backend (which talks to MySQL).
3.  **Troubleshooting:**
    *   If 502 Bad Gateway: Backend might be unhealthy (check `install_backend.sh` logs).
    *   If Frontend loads but no products: Database connection might be failing.
    *   **If Target Group is empty:**
        1.  Go to **EC2 -> Auto Scaling Groups**.
        2.  Select your ASG (e.g., `asg-backend`).
        3.  Scroll to the **"Load balancing"** section.
    *   **If ASG has NO instances (Capacity is 0):**
        1.  Go to the **"Activity"** tab in your ASG.
        2.  Look at the **"Activity history"**.
        3.  It will show a "Failed" status and a **Cause**.
        4.  Common errors:
            *   *Security group does not exist*: You might have typos in the Launch Template.
            *   *Key Pair not found*: You selected a key that doesn't exist.
            *   *Launch Template not found*: You didn't select a valid version.
            *   *Subnet issue*: You selected the wrong VPC.

---
**Congratulations!** You have manually built a production-style 3-tier architecture on AWS.
