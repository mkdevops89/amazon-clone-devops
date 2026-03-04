# 📦 Amazon-Like E-Commerce Platform (Phase 2: Docker & Containerization)

## 🚀 Phase 2 Overview
This branch (`phase-2-docker`) represents the **Containerization Phase** of a production-grade e-commerce application. 

Building upon the manual setups, this phase packages the entire application stack—Frontend, Backend, Databases, Message Brokers, and Observability tools—into **Docker Containers**. By using `docker-compose`, we can spin up the entire architecture locally or on a single cloud server (EC2) with a single command.

This drastically improves developer experience, ensures consistency across environments ("it works on my machine"), and serves as the foundation for Kubernetes orchestration in future phases.

### 🏗 Architecture
*   **Frontend**: Next.js 14 (React) container
*   **Backend**: Spring Boot 3.2 (Java 17) container
*   **Database**: MySQL 8.0 container (with mounted volume for data persistence)
*   **Cache**: Redis Alpine container
*   **Messaging**: RabbitMQ container
*   **Code Quality**: SonarQube container
*   **Observability**: Datadog Agent container (Metrics, APM, Logs)

```mermaid
graph TD
    Client([Internet / Users])

    %% Host Environment
    subgraph DockerHost ["Docker Host (Local Machine or EC2)"]
        
        %% Docker Compose Network
        subgraph DockerNetwork ["Docker Bridge Network (app-network)"]
            
            %% Ingress
            Frontend["amazon-frontend (Port 3000)"]
            Backend["amazon-backend (Port 8080)"]
            
            %% Data Services
            subgraph DataLayer ["Stateful Containers"]
                direction TB
                MySQL[("amazon-mysql (Port 3306)")]
                Redis[("amazon-redis (Port 6379)")]
                RabbitMQ>"amazon-rabbitmq (Port 5672, 15672)"]
            end
            
            %% Observability & Quality
            subgraph Tools ["Tooling Containers"]
                direction TB
                SonarQube["amazon-sonarqube (Port 9000)"]
                Datadog["amazon-datadog (Agent)"]
            end
        end
        
        %% Docker Volumes
        subgraph Volumes ["Docker Volumes"]
            VolMySQL[(mysql_data)]
            VolSonar[(sonarqube_data)]
        end
    end

    %% Ingress Traffic Flow
    Client -->|HTTP:3000| Frontend
    Client -->|HTTP:8080| Backend
    Client -->|HTTP:9000| SonarQube
    
    %% Internal API Routing (Container to Container)
    Frontend -.->|API Requests| Backend

    %% Internal Data Connections
    Backend --> MySQL
    Backend --> Redis
    Backend --> RabbitMQ

    %% Volume Mounts
    MySQL -.->|Persists Data| VolMySQL
    SonarQube -.->|Persists Data| VolSonar

    %% Styling
    classDef dockerhost fill:#f9f9f9,stroke:#0db7ed,stroke-dasharray: 5 5,stroke-width:2px
    classDef network fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:black
    classDef app fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px
    classDef db fill:#2173b8,stroke:#175182,color:white,stroke-width:2px
    classDef tool fill:#6ab165,stroke:#388e3c,color:white,stroke-width:2px
    classDef volume fill:#ffcc99,stroke:#ff9900,color:black,stroke-width:2px
    
    class DockerHost dockerhost
    class DockerNetwork network
    class Frontend,Backend app
    class MySQL,Redis,RabbitMQ db
    class SonarQube,Datadog tool
    class VolMySQL,VolSonar volume
```

## ⚡ Quick Start

### Local Development (Docker Compose)
Run the full stack locally with one command:
```bash
docker compose up -d --build
```
*   **Frontend**: [http://localhost:3000](http://localhost:3000)
*   **Backend API**: [http://localhost:8080](http://localhost:8080)
*   **SonarQube**: [http://localhost:9000](http://localhost:9000)

*(To stop the stack and remove containers: `docker compose down`)*

## 📚 Technical Playbooks & Walkthroughs

The detailed step-by-step guides for utilizing this architecture are provided below:

*   **[Phase 2 Walkthrough (`phase_2_walkthrough.md`)](./phase_2_walkthrough.md)** - Instructions on how to build, run, and troubleshoot the Dockerized stack locally or on an EC2 instance.
*   **[Test Cases (`testcases.md`)](./testcases.md)** - Verification procedures to ensure all containers, APIs, and the Datadog integration are functioning correctly.

## 📂 Project Structure
```text
.
├── backend/                  # Spring Boot Application Source Code & Dockerfile
├── frontend/                 # Next.js Application Source Code & Dockerfile
├── ops/
│   ├── docker/               # Database Initialization Scripts (e.g., init.sql)
│   ├── scripts/              # EC2 Setup Script (install Docker on Ubuntu)
│   └── vagrant/              # Vagrant configs for local VM-based testing
├── docker-compose.yml        # Orchestrates the 6 containers
├── phase_2_walkthrough.md    # Master Runbook for Docker deployment
└── testcases.md              # Infrastructure and API Verification
```

---
*Created as the Containerization iteration for a DevOps Reference Architecture journey.*
