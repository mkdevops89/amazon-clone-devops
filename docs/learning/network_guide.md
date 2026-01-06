# 🌐 Networking Cheat Sheet

This project uses networking at 4 different levels. Here is exactly what you need to know.

## 1. The Ports (The Basics)
Memorize these. They are the "doors" to your services.
*   **3000**: **Frontend** (Next.js Application).
*   **8080**: **Backend** (Spring Boot API).
*   **3306**: **MySQL** (Database protocol).
*   **6379**: **Redis** (Cache protocol).
*   **5672**: **RabbitMQ** (Messaging protocol).
*   **15672**: **RabbitMQ UI** (Management Dashboard).
*   **9000**: **SonarQube** (Code Quality UI).
*   **9090**: **Prometheus** (Metrics UI).

---

## 2. Docker Networking (Local)
*How containers talk on your laptop.*
*   **Concept**: `docker-compose` creates a virtual network. Services can talk to each other using their **Service Name** as a hostname.
*   **Example**: The Backend connects to `jdbc:mysql://mysql:3306/...`. It uses the hostname `mysql`, NOT `localhost`.
*   **Why**: Inside the container, `localhost` means "me". `mysql` means "the other container".

---

## 3. AWS Networking (The Cloud)
*How servers talk in Phase 3.*
*   **VPC (Virtual Private Cloud)**: Your own isolated slice of the AWS cloud.
    *   `10.0.0.0/16`: The overall IP range.
*   **Subnets**:
    *   **Public (10.0.1.0/24)**: Services that talk to the internet (Load Balancer, NAT Gateway).
    *   **Private (10.0.10.0/24)**: Services that stay hidden (EKS Nodes, RDS Database).
*   **Security Groups (Firewalls)**:
    *   **Bad**: "Allow All 0.0.0.0/0".
    *   **Good**: "Allow Port 3306 ONLY from the EKS Security Group". (This is what our Terraform does).

---

## 4. Kubernetes Networking (The Enterprise)
*How Pods talk in Phase 6.*
*   **ClusterIP**: An internal IP address only visible *inside* the cluster.
    *   Example: Backend Service gets an IP `10.100.50.5`. Frontend calls this IP.
*   **LoadBalancer**: An external IP address exposed to the *world*.
    *   Example: Frontend Service gets a classic AWS Load Balancer (ELB) so you can visit `http://amazon-clone.com`.
*   **CoreDNS**: Kubernetes' internal DNS server.
    *   It allows Frontend to call `http://backend-service:8080` instead of memorizing IP addresses.

---

## 5. Troubleshooting (What to check when it breaks)
*   **"Connection Refused"**: The service isn't running, or you hit the wrong port.
*   **"Connection Timed Out"**: It's a FIREWALL (Security Group) issue. The packet is being dropped silently.
*   **"Unknown Host"**: It's a DNS issue. The environment variable (e.g., `SPRING_DATASOURCE_URL`) has a typo in the hostname.
