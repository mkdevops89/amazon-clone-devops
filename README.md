# 📦 Amazon-Like E-Commerce Platform (DevOps Reference Architecture)

## 🚀 Project Overview
This repository contains a production-grade, full-stack e-commerce application designed as a **DevOps Reference Architecture**. It demonstrates modern Cloud-Native practices, including Microservices, Infrastructure as Code (IaC), GitOps, and DevSecOps.

### 🏗 Architecture
*   **Frontend**: Next.js 14 (React) with a Premium Custom UI.
*   **Backend**: Spring Boot 3.2 (Java 17) REST API.
*   **Database**: MySQL 8.0 (Primary) + Redis (Cache/Session).
*   **Messaging**: RabbitMQ (Asynchronous Order Processing).

## 🛠 Technology Stack

| Category | Tools Used | Location |
|----------|------------|----------|
| **Containerization** | Docker, Docker Compose | `Dockerfile`, `docker-compose.yml` |
| **Orchestration** | Kubernetes (EKS/AKS/GKE), Helm | `ops/k8s`, `ops/helm` |
| **Infrastructure (IaC)** | Terraform (AWS, Azure, GCP) | `ops/terraform` |
| **CI/CD** | Jenkins, GitLab CI, Nexus | `Jenkinsfile`, `.gitlab-ci.yml` |
| **GitOps** | ArgoCD | `ops/argocd` |
| **Observability** | Prometheus, Grafana, Datadog | `ops/monitoring` |
| **Security** | Trivy, Checkov, OWASP, SonarQube, **AWS Secrets Manager**, **External Secrets Operator** | CI Pipelines, `ops/k8s/secrets` |
| **Provisioning** | Ansible, Vagrant | `ops/ansible`, `ops/vagrant` |

## 🚀 Key Features (Enterprise Grade)

### 🛡️ DevSecOps Pipeline
*   **SAST**: SonarQube (Static Analysis)
*   **SCA**: Snyk & Trivy (Dependency Scanning) - *[Added]*
*   **DAST**: OWASP ZAP (Runtime Attacks) - *[Added]*
*   **Container Security**: Trivy Image Scanning

### ☁️ Advanced Infrastructure
*   **Immutable Infrastructure**: HashiCorp Packer (AMI Baking)
*   **Secret Management**: HashiCorp Vault (Dynamic Secrets)
*   **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
*   **GitOps**: ArgoCD (Continuous Deployment)
*   **Service Mesh**: Istio (Traffic Management) - *[Added]*
*   **IoC Wrapper**: Terragrunt (DRY Terraform) - *[Added]*


## ⚡ Quick Start

### Option 1: Docker Compose (Easiest)
Run the full stack locally with one command:
```bash
docker-compose up -d --build
```
*   **Frontend**: [http://localhost:3000](http://localhost:3000)
*   **Backend API**: [http://localhost:8080](http://localhost:8080)
*   **SonarQube**: [http://localhost:9000](http://localhost:9000)

### Option 2: Vagrant (VM Isolation)
Spin up a self-contained Development VM:
```bash
cd ops/vagrant
vagrant up
```
*   The VM will automatically provision Docker and start the app at `http://192.168.33.10:3000`.

### Option 3: Kubernetes (Helm)
Deploy to a cluster:
```bash
helm install amazon-shop ./ops/helm
```


## 📚 Documentation
> **[Start Here: Project Documentation & Learning Guides](./docs/documentation.md)**
All guides, architectural diagrams, and runbooks have been moved to the `docs/` directory.

## 📂 Project Structure
```
.
├── backend/            # Spring Boot Application
├── docs/               # 📚 Project Documentation & Learning Guides
│   ├── career/         # Resume & Interview Prep
│   ├── diagrams/       # Architecture Diagrams
│   └── learning/       # Step-by-Step DevOps Guides
├── frontend/           # Next.js Application
├── ops/                # DevOps Configurations
│   ├── ansible/        # Configuration Management
│   ├── argocd/         # GitOps Manifests
│   ├── docker/         # Initialization Scripts
│   ├── helm/           # Helm Charts
│   ├── k8s/            # Raw Kubernetes Manifests
│   ├── monitoring/     # Prometheus/Grafana Values
│   ├── packer/         # AMI Maintenance
│   ├── terraform/      # Legacy IaC
│   ├── terragrunt/     # Advanced IaC (DRY)
│   └── vagrant/        # VM Provisioning
├── docker-compose.yml  # Local Orchestration
├── Jenkinsfile         # Jenkins Pipeline
└── .gitlab-ci.yml      # GitLab Pipeline
```

## 🔐 Credentials (Demo)
*   **User/Pass**: `admin` / `admin`
*   **SonarQube**: `admin` / `admin`
*   **Grafana**: `admin` / `admin`

---
*Created as a Portfolio Masterpiece for DevOps Engineering.*
