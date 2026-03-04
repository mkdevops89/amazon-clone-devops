# 📦 Amazon-Like E-Commerce Platform (Phase 4: Kubernetes)

## 🚀 Phase 4 Overview
This branch (`phase-4-k8s`) represents the **Kubernetes Orchestration Phase** of a production-grade e-commerce application. 

Building upon the Docker containers from Phase 2 and the AWS Infrastructure provisioned in Phase 3, this phase deploys the stateless application components (Frontend & Backend) into **Amazon EKS (Elastic Kubernetes Service)**. 

By utilizing Kubernetes Deployments, Services, and Secrets, we achieve a highly available, self-healing, and easily scalable architecture that elegantly connects to our Terraform-provisioned Managed Data Layer.

### 🏗 EKS Architecture
*   **Compute Foundation**: AWS EKS Control Plane & Auto Scaling Node Groups
*   **Application Workloads**:
    *   **Frontend**: Next.js 14 replicas
    *   **Backend**: Spring Boot 3.2 replicas
*   **Traffic Ingress**: AWS Application Load Balancer (ALB) automatically provisioned by Kubernetes Services.
*   **Stateful Dependencies**: External AWS Managed Services (RDS, ElastiCache, Amazon MQ) securely injected via Kubernetes Secrets.

```mermaid
graph TD
    Client([Internet / Users])

    %% AWS Environment
    subgraph AWS ["AWS VPC Ecosystem"]
        
        %% Kubernetes Cluster
        subgraph EKS ["Amazon Elastic Kubernetes Service (EKS)"]
            
            %% ALB ingress
            ALB{{"AWS Application Load Balancer"}}
            
            %% EKS Worker Nodes
            subgraph NodeGroup ["Worker Nodes (t3.medium)"]
                
                %% Frontend Deployment
                subgraph DeployFront ["Frontend Deployment"]
                    PodFront1(Frontend Pod 1)
                    PodFront2(Frontend Pod 2)
                    SvcFront[Frontend Service]
                end

                %% Backend Deployment
                subgraph DeployBack ["Backend Deployment"]
                    PodBack1(Backend Pod 1)
                    PodBack2(Backend Pod 2)
                    SvcBack[Backend Service]
                end

                %% Secrets
                SecretDb[(K8s Secret: db-secrets)]
            end
        end

        %% External Data Layer from Phase 3
        subgraph DataLayer ["AWS Managed Services (via Terraform)"]
            direction TB
            RDS[("Amazon RDS (MySQL)")]
            ElastiCache[("Amazon ElastiCache (Redis)")]
            AmazonMQ("Amazon MQ (RabbitMQ)")
        end
    end

    %% Ingress Traffic Flow
    Client -->|HTTP Request| ALB
    ALB -->|Port 80| SvcFront
    
    %% K8s Internal Routing
    SvcFront --> PodFront1 & PodFront2
    PodFront1 & PodFront2 -.->|API Calls| ALB
    ALB -->|/api/*| SvcBack
    SvcBack --> PodBack1 & PodBack2
    
    %% Secrets injection
    SecretDb -->|Injects DB Creds| PodBack1 & PodBack2

    %% External Data Connections
    PodBack1 & PodBack2 --> RDS
    PodBack1 & PodBack2 --> ElastiCache
    PodBack1 & PodBack2 --> AmazonMQ

    %% Styling
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef eks fill:#e1f5fe,stroke:#0288d1,stroke-width:2px,color:black
    classDef pod fill:#d4ecd3,stroke:#388e3c,color:black
    classDef svc fill:#ffeb3b,stroke:#fbc02d,color:black
    classDef secret fill:#f8bbd0,stroke:#d81b60,color:black
    classDef db fill:#2173b8,stroke:#175182,color:white,stroke-width:2px
    classDef alb fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px,shape:hexagon
    
    class AWS aws
    class EKS,NodeGroup eks
    class PodFront1,PodFront2,PodBack1,PodBack2 pod
    class SvcFront,SvcBack svc
    class SecretDb secret
    class RDS,ElastiCache,AmazonMQ db
    class ALB alb
```

## 🛠 Kubernetes Deployment (Runbooks)

To deploy the application into the EKS cluster, follow the master runbook. *Note: You must have an active EKS cluster running from Phase 3.*

1. **[EKS Deployment Runbook (`phase_4_walkthrough.md`)](./phase_4_walkthrough.md)**
   * Fetching RDS credentials from Terraform and creating Kubernetes Secrets.
   * Building and pushing Docker images to AWS ECR.
   * Running the smart deployment scripts (`deploy_k8s.sh`).
2. **[Kubernetes Verification Tests (`phase_4_testcases.md`)](./phase_4_testcases.md)**
   * Checking Pod health, Service endpoints, and verifying full application connectivity.

## 📂 Project Structure
```text
.
├── backend/                  # Application code + deployment manifests
├── frontend/                 # Application code + deployment manifests
├── ops/
│   ├── k8s/                  # Raw Kubernetes Manifests (YAML)
│   │   ├── backend.yaml
│   │   └── frontend.yaml
│   ├── scripts/              # Helper Bash Automation
│   │   ├── deploy_k8s.sh           # Replaces ENV vars and deploys
│   │   └── update_k8s_secrets.sh   # syncs TF DB passwords -> K8s Secrets
│   └── terraform/            # Infrastructure State Foundation
├── phase_4_testcases.md      # Verification procedures for K8s deployments
└── phase_4_walkthrough.md    # Master Runbook for EKS orchestration
```

---
*Created as the Container Orchestration iteration for a DevOps Reference Architecture journey.*
