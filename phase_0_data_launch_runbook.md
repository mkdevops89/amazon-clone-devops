# Phase 0: Data Layer Launch Runbook (AWS Console)

**Objective:** Launch the 3 Stateful Servers (MySQL, Redis, RabbitMQ) into Private Subnets.

## 🚀 General Settings (For All 3 Instances)
*   **AMI:** Amazon Linux 2023 AMI (HVM)
*   **Architecture:** 64-bit (x86)
*   **Network:** `amazon-vpc-manual`
*   **Subnet:** `private-subnet-1` (or `private-subnet-2`)
*   **Auto-assign Public IP:** Disable (Enable only if in Public Subnet for testing, but typically Disable for Private)
    *   *Note: Since they are in Private Subnet, they need NAT Gateway to install software.*
*   **Security Group:** `sg-data`
*   **IAM Instance Profile:** `ec2-ssm-role` (If created)

---

## 💾 1. MySQL Server
1.  **Name:** `mysql-server`
2.  **Instance Type:** `t3.micro`
3.  **Advanced Details -> User Data:**
    *   Open `ops/scripts/phase_0/install_mysql.sh`
    *   **Note:** This updated script now *automatically* installs Git, clones the repo, and imports `db_backup.sql`.
    *   Copy content -> Paste into User Data box.
4.  **Launch Instance.**

## 💾 2. Redis Server
1.  **Name:** `redis-server`
2.  **Instance Type:** `t3.micro`
3.  **Advanced Details -> User Data:**
    *   Open `ops/scripts/phase_0/install_redis.sh`
    *   Copy content -> Paste into User Data box.
4.  **Launch Instance.**

## 💾 3. RabbitMQ Server
1.  **Name:** `rabbitmq-server`
2.  **Instance Type:** `t3.small` (Needs slightly more RAM)
3.  **Advanced Details -> User Data:**
    *   Open `ops/scripts/phase_0/install_rabbitmq.sh`
    *   Copy content -> Paste into User Data box.
4.  **Launch Instance.**

---

## 📝 Post-Launch Checklist
Wait 5 minutes for them to boot and install software. Then go to the EC2 Console list and write down their **Private IPv4 addresses**:

| Server | Private IP (Example) | Actual IP (Fill this in!) |
| :--- | :--- | :--- |
| **MySQL** | 10.0.3.45 | `___________________` |
| **Redis** | 10.0.3.12 | `___________________` |
| **RabbitMQ** | 10.0.3.99 | `___________________` |

> **Next Step:** You will need these IPs to configure the Backend Launch Template!
