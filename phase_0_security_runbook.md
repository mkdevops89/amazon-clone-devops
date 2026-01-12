# Phase 0: Security Group Runbook (AWS Console)

**Objective:** Create the firewall rules (Security Groups) to secure our 3-Tier Architecture.
**Region:** `us-east-1` (N. Virginia)
**VPC:** `amazon-vpc-manual` (Select this for ALL groups)

## 🛡️ 1. Load Balancer SG (`sg-alb`)
*   **Name:** `sg-alb`
*   **Description:** Allow Public Traffic
*   **Inbound Rules:**
    *   **Type:** HTTP | **Port:** 80 | **Source:** `0.0.0.0/0` (Anywhere IPv4)
    *   **Type:** HTTPS | **Port:** 443 | **Source:** `0.0.0.0/0` (Anywhere IPv4)

## 🛡️ 2. Application SG (`sg-app`)
*   **Name:** `sg-app`
*   **Description:** Allow Traffic from ALB
*   **Inbound Rules:**
    *   **Type:** Custom TCP | **Port:** 3000 (Frontend) | **Source:** `sg-alb` (Select from list)
    *   **Type:** Custom TCP | **Port:** 8080 (Backend) | **Source:** `sg-alb`
    *   **Type:** SSH | **Port:** 22 | **Source:** `0.0.0.0/0` (Optional: Only if you need to debug, preferably MyIP)

## 🛡️ 3. Database SG (`sg-data`)
*   **Name:** `sg-data`
*   **Description:** Allow Traffic from App
*   **Inbound Rules:**
    *   **Type:** MYSQL/Aurora | **Port:** 3306 | **Source:** `sg-app`
    *   **Type:** Custom TCP | **Port:** 6379 (Redis) | **Source:** `sg-app`
    *   **Type:** Custom TCP | **Port:** 5672 (RabbitMQ) | **Source:** `sg-app`
    *   **Type:** Custom TCP | **Port:** 15672 (MQ Console) | **Source:** `sg-app` (Or `sg-alb` if you want public console access, risky)

## 🔑 IAM Role (Optional but Recommended)
*   **Name:** `ec2-ssm-role`
*   **Service:** EC2
*   **Policies:** `AmazonSSMManagedInstanceCore`
*   *Why?* Allows you to use "Session Manager" to connect to private instances without opening Port 22/SSH.
