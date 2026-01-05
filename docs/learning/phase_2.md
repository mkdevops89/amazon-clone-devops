# Phase 2: Dockerization (Containerization)

## 🎯 Goal
Package our messy "Manual" setup from Phase 1 into clean, portable **Docker Containers**. This ensures:
*   "It works on my machine" -> "It works EVERYWHERE".
*   No need to install Java/Node/MySQL on the host heavily.

## 🏗️ Architecture
We treat the entire stack as code using `docker-compose.yml`.

### 1. The Container Stack
*   **Frontend**: `amazon-frontend:latest` (Node 18 Alpine)
*   **Backend**: `amazon-backend:latest` (Java 17 Temurin)
*   **Database**: `mysql:8.0`
*   **Cache**: `redis:alpine`
*   **Queue**: `rabbitmq:3-management`

---

## 🚀 How to Run (The "Magic" Command)

### 1. Build & Start
From the project root (where `docker-compose.yml` is):
```bash
docker-compose up -d --build
```
*   `--build`: Forces meaningful rebuild of the images.
*   `-d`: Detached mode (runs in background).

### 2. Verify Containers
```bash
docker-compose ps
```
You should see 5 services:
*   `amazon-frontend` (Port 3000)
*   `amazon-backend` (Port 8080)
*   `amazon-mysql`
*   `amazon-redis`
*   `amazon-rabbitmq`

### 3. Check Logs
If something breaks (e.g., Backend fails to connect to DB):
```bash
docker-compose logs -f backend
```

---

## 🧹 Cleanup
To stop everything and save battery:
```bash
docker-compose down
```

To stop and **delete** data (Factory Reset):
```bash
docker-compose down -v
```
*(Warning: deletes your database data!)*

---

## 🧠 Key Concepts Learned
1.  **Multi-Stage Builds**: Look at `backend/Dockerfile`. We compile code in one stage (Maven) and only copy the JAR to the final stage (JRE). This creates tiny images.
2.  **Networking**: Configuring `backend` to talk to `mysql` using the service name (DNS), not IP addresses.
3.  **Persistence**: Using Docker Volumes (`mysql_data`) to keep data even if the container dies.

## ⏭️ Next Steps
Now that we have containers, how do we deploy them to the Cloud? Let's use **Terraform** in [Phase 3](./phase_3.md).
