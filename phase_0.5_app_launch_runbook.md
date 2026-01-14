# Phase 0.5: App Layer Runbook (Managed Services Edition)

**Objective:** Deploy the Backend and Frontend, connecting them to your new AWS Managed Services.

---

## 🚀 1. Launch Templates (Updated)

### LT 1: Backend (Updated for Managed Services)
*   **Name:** `lt-backend-managed`
*   **AMI:** Amazon Linux 2023
*   **Instance Type:** `t3.medium`
*   **Security Group:** `sg-app`
*   **User Data:**
    *   Open `ops/scripts/phase_0/install_backend.sh`.
    *   **Replacements:**
        *   `DB_HOST`: Paste your **RDS Endpoint** (remove `:3306` if present).
        *   `REDIS_HOST`: Paste your **ElastiCache Primary Endpoint**.
        *   `RABBITMQ_HOST`: Paste your **AmazonMQ Endpoint** (Hostname ONLY, e.g., `b-123...mq.us-east-1.amazonaws.com`).
        *   **CRITICAL CHANGE:** AmazonMQ uses SSL (Port 5671). You must update the `SPRING_RABBITMQ_PORT` to `5671` and ensure `SPRING_RABBITMQ_SSL_ENABLED` is `true`.
        *   *Wait! The current script might not support SSL toggles via env vars easily if not in application.properties.*
    *   **Action:** Paste the edited script.

> **💡 Script Note:** The standard `install_backend.sh` passes variables to the Spring Boot App. Ensure your `application.properties` respects `SPRING_RABBITMQ_SSL_ENABLED` or defaults to false.
> *If your application doesn't support AMQPS explicitly, you might need to enable `Spring Boot` SSL properties.*
> Assuming standard Spring Boot: `spring.rabbitmq.ssl.enabled=true`.

### LT 2: Frontend
*   **Same as Phase 0.**
*   Point `NEXT_PUBLIC_API_URL` to the **ALB DNS Name**.

---

## ⚙️ 2. Auto Scaling Groups
*   **Backend ASG:** Update to use `lt-backend-managed`.
    *   *Tip:* If you already have `asg-backend`, just go to "Instance Refresh" or "Launch Template" settings and switch versions/templates. Then start an Instance Refresh.
*   **Frontend ASG:** No changes needed if the ALB is the same.

---

## 🧹 Cleanup Required
Since you moved to Managed Services, you should **Terminate** the old EC2 Data Instances:
1.  Review your "Instances" list.
2.  Terminate `mysql-server`, `redis-server`, `rabbitmq-server`.
3.  **Verify:** Your Backend should now be connecting to RDS/ElastiCache/AmazonMQ.
