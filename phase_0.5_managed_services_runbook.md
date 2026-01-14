# Phase 0.5: Managed Data Layer Runbook (AWS Console)

**Objective:** Launch AWS Managed Services (RDS, ElastiCache, AmazonMQ) to replace the manual EC2 data layer.
**Region:** `us-east-1` (N. Virginia)

---

## ⚠️ Free Tier Warning
These services can be expensive. Strictly follow the **Instance Types** listed below to stay within the AWS Free Tier (12 months for new accounts).
*   **RDS:** 750 hrs/mo of `db.t3.micro` or `db.t2.micro`.
*   **ElastiCache:** 750 hrs/mo of `cache.t2.micro` or `cache.t3.micro`.
*   **AmazonMQ:** 750 hrs/mo of `mq.t3.micro`.

---

## 🛡️ Pre-Requisite: Security Groups
The Managed Services need to allow traffic from your App.
*   **Go to:** VPC -> Security Groups -> `sg-data`.
*   **Verify/Add Inbound Rules:**
    *   **Type:** MySQL/Aurora (3306) -> Source: `sg-app`
    *   **Type:** Custom TCP (6379) -> Source: `sg-app` (Redis)
    *   **Type:** Custom TCP (5671) -> Source: `sg-app` (RabbitMQ - Note: AmazonMQ uses SSL port 5671 by default, unlike raw RabbitMQ 5672).

---

## 🗄️ 1. Amazon RDS (MySQL)
1.  **Go to:** RDS Console -> **Create database**.
2.  **Choose a database creation method:** Standard create.
3.  **Engine options:** MySQL.
4.  **Engine Version:** MySQL 8.0.x.
5.  **Templates:** **Free Tier**. (Crucial Step!)
6.  **Settings:**
    *   **DB Instance Identifier:** `amazon-rds`
    *   **Master username:** `admin`
    *   **Master password:** `password123` (Confirm password).
7.  **Instance configuration:** `db.t3.micro`.
8.  **Connectivity:**
    *   **VPC:** `amazon-vpc-manual`
    *   **Public access:** NO.
    *   **VPC Security Group:** Select `sg-data` (Remove 'default').
    *   **Availability Zone:** No preference.
9.  **Additional configuration:**
    *   **Initial database name:** `amazon_db` (Important! If you leave this blank, it won't create the DB).
    *   **Backup:** Enable automatic backups (Retention: 7 days).
10. **Create database.**

> **📝 Post-Launch:** Wait for status "Available". Copy the **Endpoint** (e.g., `amazon-rds.cw...us-east-1.rds.amazonaws.com`).

---

## ⚡ 2. Amazon ElastiCache (Redis)
1.  **Go to:** ElastiCache Console -> **Redis clusters** -> **Create Redis OSS cluster**.
2.  **Cluster settings:**
    *   **Design your own cluster**.
    *   **Creation method:** Configure and create a new cluster.
    *   **Cluster mode:** Disabled (Simpler for basic app).
    *   **Name:** `amazon-redis`
3.  **Cluster settings (Node type):**
    *   **Node type:** `cache.t2.micro` (Search for 't2').
    *   **Number of replicas:** 0 (Free Tier limit is usually 1 node, but verify your account).
4.  **Connectivity:**
    *   **Subnet group:** Create new. Name: `amazon-cache-subnet-group`. VPC: `amazon-vpc-manual`. Select **Private Subnets**.
    *   **VPC Security Groups:** Select `sg-data`.
5.  **Create.**

> **📝 Post-Launch:** Wait for status "Available". Copy the **Primary Endpoint** (e.g., `amazon-redis.abcdef.0001.use1.cache.amazonaws.com`).

---

## 🐰 3. Amazon MQ (RabbitMQ)
1.  **Go to:** Amazon MQ Console -> **Create brokers**.
2.  **Broker engine type:** RabbitMQ.
3.  **Deployment mode:** Single-instance broker.
4.  **Settings:**
    *   **Broker name:** `amazon-mq`
    *   **Broker instance type:** `mq.t3.micro`.
    *   **RabbitMQ Access:**
        *   **Username:** `admin`
        *   **Password:** `password1234`
5.  **Connectivity:**
    *   **Access type:** Private access.
    *   **VPC:** `amazon-vpc-manual`.
    *   **Subnets:** Select a Private Subnet.
    *   **Security groups:** Select `sg-data`.
6.  **Create broker.**

> **📝 Post-Launch:** Wait (can take 15 mins). Click the Broker Name.
> Under **Connections**, look for the **AMQP endpoint** (e.g., `amqps://b-1234...@mq.us-east-1.amazonaws.com:5671`).
> *Note: AmazonMQ enforces SSL (amqps) and port 5671.*

---

## 📋 Critical Data Collection
You cannot proceed to the App Launch without these three endpoints:

1.  **RDS Endpoint:** `_________________________________________________________`
2.  **Redis Endpoint:** `_________________________________________________________`
3.  **RabbitMQ Endpoint:** `_________________________________________________________`
    *(Use the URL without `amqps://` and port for the host field if the script splits them, or full URL depending on your script logic).*
