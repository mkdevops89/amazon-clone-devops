# Phase 1: Application Setup (Manual & VM)

## 🎯 Goal
Get the "Amazon-Like" application running manually. This helps you understand the components before we hide them inside containers (Docker) or Kubernetes.

## 🏗️ Architecture (The "Hard" Way)
We will run each component as a separate process on your machine (or VM).
1.  **MySQL**: Running as a background service.
2.  **Spring Boot**: Running as a JAR file (`java -jar`).
3.  **Next.js**: Running via Node (`npm run dev`).
4.  **RabbitMQ & Redis**: Running as background services.

---

## 🛠️ Option 1: The "Virtual Machine" Way (Recommended)
Instead of installing Java/MySQL on your laptop, we use **Vagrant** to create an isolated Ubuntu server.

### 1. Prerequisites
*   Install [VirtualBox](https://www.virtualbox.org/)
*   Install [Vagrant](https://www.vagrantup.com/)

### 2. Start the Environment
```bash
cd ops/vagrant
vagrant up
```
*   This downloads Ubuntu, installs Docker (as a helper), and starts the app.
*   **URL**: `http://192.168.33.10:3000`

### 3. SSH into the Machine
To feel like a real SysAdmin, log into "Production":
```bash
vagrant ssh
# You are now inside the Linux server!
cd /opt/amazonlikeapp
ls -la
```

---

## 💻 Option 2: The "LocalHost" Way (Manual)
If you want to run everything directly on your Mac.

### 1. Prerequisites
*   Java 17 JDK
*   Node.js 18+
*   MySQL 8.0 Server (Running on port 3306)

### 2. Configure Database
Login to your local MySQL and create the schema:
```sql
CREATE DATABASE amazonlike_db;
-- (Then run the script from ops/docker/mysql/init.sql)
```

### 3. Start Backend
```bash
cd backend
./mvnw clean package
java -jar target/backend-0.0.1-SNAPSHOT.jar
```

### 4. Start Frontend
```bash
cd frontend
npm install
npm run dev
```
*   **URL**: `http://localhost:3000`

---

## 🔍 Verification
How do you know it's working?
1.  Go to `http://localhost:3000` (or the VM IP).
2.  Can you see the "Hero Banner"?
3.  Can you click "Login" (use `admin`/`admin`)?
4.  **DevOps Check**: Look at the Backend logs. Do you see `Started BackendApplication in 3.4 seconds`?

## ⏭️ Next Steps
Now that you know how painful it is to install Java, MySQL, and Node manually... let's fix that with **Docker** in [Phase 2](./phase_2.md).
