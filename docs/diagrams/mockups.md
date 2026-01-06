# 🎨 Project Architecture Mockups (Visual Guide)

This document contains visual diagrams for every phase of the "Amazon-Like" DevOps Project.
These diagrams illustrate the evolution of the infrastructure from local VMs to a full Cloud-Native Kubernetes cluster.

---

## 🟢 Phase 1: Manual Provisioning (Single/Multi-VM)
**Goal:** Understand the components (App, DB, Cache, Queue) by installing them manually.

```mermaid
graph TD
    User((User)) -->|HTTP:80| Nginx[Load Balancer VM]
    Nginx -->|Proxy:8080| Tomcat[App Server VM]
    Tomcat -->|JDBC:3306| DB[(MySQL VM)]
    Tomcat -->|Cache:6379| Redis[(Redis VM)]
    Tomcat -->|AMQP:5672| Rabbit[RabbitMQ VM]
    
    subgraph "Local Virtual Network (Vagrant/VirtualBox)"
        Nginx
        Tomcat
        DB
        Redis
        Rabbit
    end
```

---

## 🟢 Phase 1b: Enterprise Manual Setup (The VProfile Way)
**Goal:** Rigorous separation of concerns using CentOS/Enterprise Linux standards.

```mermaid
graph LR
    Dev[Developer Laptop] -- SSH --> LB01
    Dev -- SSH --> APP01
    Dev -- SSH --> DB01
    
    subgraph "Private Network"
        LB01(LB01: Nginx) --> APP01(APP01: Java Spring)
        APP01 --> DB01[(DB01: MariaDB)]
        APP01 --> MC01[(MC01: Redis)]
        APP01 --> RMQ01(RMQ01: RabbitBroker)
    end
```

---

## 🔵 Phase 2: Containerization (Docker Compose)
**Goal:** Simplify setup by packaging everything into containers. No more manual `yum install`.

```mermaid
graph TD
    User -->|Localhost:80| Frontend[Next.js Container]
    User -->|Localhost:8080| Backend[Spring Boot Container]
    
    subgraph "Docker Host"
        Frontend -.->|API Call| Backend
        Backend -->|Network: AmazonNetwork| MySQL[(MySQL Container)]
        Backend -->|Network: AmazonNetwork| Redis[(Redis Container)]
        Backend -->|Network: AmazonNetwork| Rabbit[(RabbitMQ Container)]
    end
```

---

## 🟠 Phase 3: Cloud Infrastructure (AWS Terraform)
**Goal:** Replicate the network in the real cloud using Infrastructure as Code.

```mermaid
graph TB
    tf(Terraform CLI) -->|Apply| AWS
    
    subgraph "AWS Cloud (Region: us-east-1)"
        VPC[VPC]
        subgraph "Public Subnet"
            IGW[Internet Gateway]
            ALB[Application Load Balancer]
        end
        
        subgraph "Private Subnet"
            EKS[EKS Cluster (Nodes)]
            RDS[(RDS MySQL)]
            ElastiCache[(ElastiCache Redis)]
        end
    end
    
    IGW --> ALB
    ALB --> EKS
    EKS --> RDS
    EKS --> ElastiCache
```

---

## 🟣 Phase 4: CI/CD Pipeline (Jenkins)
**Goal:** Automate the build and test process.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as GitHub
    participant Jen as Jenkins
    participant Sonar as SonarQube
    participant Nexus as Nexus Repo
    participant Docker as DockerHub

    Dev->>Git: Push Code
    Git->>Jen: Webhook Trigger
    Jen->>Jen: Checkout Code
    Jen->>Jen: Build (Maven/NPM)
    Jen->>Jen: Build Docker Images
    Jen->>Sonar: Run Static Analysis
    Sonar-->>Jen: Quality Gate Pass/Fail
    Jen->>Nexus: Upload JAR/Artifacts
    Jen->>Docker: Push Image
    Jen-->>Dev: Slack Notification (Success/Fail)
```

---

## 🔒 Phase 5: DevSecOps (Security Scanning)
**Goal:** Shift security left. Catch vulnerabilities before they hit production.

```mermaid
graph LR
    Code[Source Code] --> Checkov{Checkov IaC Scan}
    Checkov -- Pass --> Build[Build Artifact]
    Build --> OWASP{OWASP Dependency Check}
    OWASP -- Pass --> Image[Docker Image]
    Image --> Trivy{Trivy Image Scan}
    Trivy -- Pass --> Registry[Docker Registry]
    
    Checkov -- Fail --> Stop[Block Pipeline]
    OWASP -- Fail --> Stop
    Trivy -- Fail --> Stop
```

---

## ☸️ Phase 6: Kubernetes Provisioning
**Goal:** Professional orchestration of containers.

```mermaid
graph TD
    Admin[Admin] -->|kubectl apply| K8s
    
    subgraph "EKS Cluster"
        Service[K8s Service (NodePort)] --> Pod1[Backend Pod 1]
        Service --> Pod2[Backend Pod 2]
        
        Pod1 --> Secret[K8s Secrets (DB Creds)]
        Pod1 --> CM[ConfigMap (Env Vars)]
        
        HPA[HPA Autoscaler] -.->|Monitors CPU| Pod1
    end
```

---

## 🔄 Phase 7: GitOps (ArgoCD)
**Goal:** The repository is the source of truth. No manual `kubectl`.

```mermaid
graph LR
    Git[Git Config Repo] -- "Syncs State" --> ArgoCD[ArgoCD Controller]
    ArgoCD -- "Applies Manifests" --> K8s[EKS Cluster]
    
    subgraph "Reconciliation Loop"
        K8s -- "Reports Status" --> ArgoCD
        ArgoCD -- "Drift Detection" --> Alert[Sync Status]
    end
```

---

## ⚙️ Phase 8: Configuration Management (Ansible)
**Goal:** Managing the underlying OS configuration.

```mermaid
graph TD
    Controller[Ansible Control Node] -->|SSH| WebServer[Web VM]
    Controller -->|SSH| DBServer[DB VM]
    
    subgraph "Playbook Execution"
        file[playbook.yml]
        role1[Role: Docker]
        role2[Role: SecurityHardening]
    end
    
    file --> Controller
```

---

## 📊 Phase 9: Observability (Prometheus & Grafana)
**Goal:** Seeing what is happening inside the black box.

```mermaid
graph LR
    App[Spring Boot App] -- "Exposes /actuator/prometheus" --> Prom[Prometheus Server]
    Prom -- "Scrapes Metrics (Pull)" --> App
    
    Grafana[Grafana Dashboard] -- "Queries (PromQL)" --> Prom
    Grafana -- "Visualizes" --> Admin[DevOps Engineer]
    
    AlertMgr[Alert Manager] -- "High CPU!" --> Slack[Slack Channel]
    Prom --> AlertMgr
```
