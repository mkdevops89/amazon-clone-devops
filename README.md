# 📦 Amazon-Like E-Commerce Platform (Phase 3: Terraform IaC)

## 🚀 Phase 3 Overview
This branch (`phase-3-terraform`) represents the **Infrastructure as Code (IaC)** evolution of a production-grade e-commerce application. 

Moving away from the manual AWS Console ClickOps approach of previous phases, this phase utilizes **Terraform** to treat infrastructure identically to application code. You can now reliably, repeatedly, and predictably provision the entire AWS backbone—including a custom VPC, Security Groups, Managed Databases (RDS, ElastiCache, Amazon MQ), and the foundation for a Kubernetes Control Plane (EKS).

This guarantees environment consistency across Development, Staging, and Production, drastically eliminates human error, and provides an auditable history of infrastructure changes via version control.

### 🏗 Provisioned Architecture
*   **Target Cloud**: Amazon Web Services (AWS)
*   **Networking**: Custom VPC (`10.0.0.0/16`) stretching across 2 Availability Zones.
*   **Subnets**: 
    *   2 Public Subnets (For Load Balancers & NAT Gateways)
    *   2 Private Subnets (For Compute, EKS Nodes, and Databases)
*   **Stateful Data Layer**: 
    *   **Amazon RDS** (MySQL 8.0)
    *   **Amazon ElastiCache** (Redis)
    *   **Amazon MQ** (RabbitMQ)
*   **Compute Foundation**: AWS EKS (Elastic Kubernetes Service) Control Plane (`v1.34`)

```mermaid
graph TD
    %% Terraform orchestration
    TF([Terraform Apply]) -.->|Provisions| AWSCloud

    %% AWS Cloud
    subgraph AWSCloud ["AWS Cloud (us-east-1)"]
        IGW((Internet Gateway))
        
        %% Virtual Private Cloud
        subgraph VPC ["Custom VPC (10.0.0.0/16)"]
            
            %% Availability Zone 1
            subgraph AZ1 ["Availability Zone 1 (us-east-1a)"]
                
                %% AZ1 Public Subnet (10.0.1.0/24)
                subgraph Public1 ["Public Subnet (10.0.1.0/24)"]
                    NAT1((NAT Gateway))
                end

                %% AZ1 Private Subnet (10.0.3.0/24)
                subgraph Private1 ["Private Subnet (10.0.3.0/24)"]
                    %% Future compute nodes go here
                    
                    subgraph DataLayer ["AWS Managed Services"]
                        direction TB
                        RDS[("Amazon RDS (MySQL 8.0)")]
                        ElastiCache[("Amazon ElastiCache (Redis)")]
                        AmazonMQ("Amazon MQ (RabbitMQ)")
                    end
                end
            end
            
            %% Availability Zone 2
            subgraph AZ2 ["Availability Zone 2 (us-east-1b)"]

                %% AZ2 Public Subnet (10.0.2.0/24)
                subgraph Public2 ["Public Subnet (10.0.2.0/24)"]
                    %% Placeholder for future HA NAT or ALBs
                    Placeholder[ ]
                    style Placeholder display:none;
                end

                %% AZ2 Private Subnet (10.0.4.0/24)
                subgraph Private2 ["Private Subnet (10.0.4.0/24)"]
                    %% EKS Control plane logically spans Subnets
                    EKS{{"Amazon EKS Control Plane (Cluster v1.34)"}}
                end
            end
        end
    end

    %% Ingress Traffic Flow
    IGW -.-> Public1
    IGW -.-> Public2

    %% Styling
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef green fill:#d4ecd3,stroke:#6ab165,stroke-width:2px,color:black
    classDef blue fill:#d2e5f3,stroke:#5b9bd5,stroke-width:2px,color:black
    classDef tf fill:#623ce4,stroke:#4a2baf,color:white,stroke-width:2px,stroke-dasharray: 5 5
    classDef gateway fill:#ff9900,stroke:#e07b00,color:white,stroke-width:2px,shape:circle
    classDef db fill:#2173b8,stroke:#175182,color:white,stroke-width:2px
    classDef compute fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px
    
    class AZ1,AZ2 aws
    class Public1,Public2 green
    class Private1,Private2 blue
    class TF tf
    class IGW,NAT1 gateway
    class RDS,ElastiCache,AmazonMQ db
    class EKS compute
```

## 🛠 Infrastructure Setup (Runbooks)

To automatically provision this production-grade environment, follow the Phase 3 master runbook.

1. **[Terraform & Infrastructure Deployment Runbook (`phase_3_walkthrough.md`)](./phase_3_walkthrough.md)**
   * Bootstrapping the S3 backend state.
   * Executing the `terraform plan` and `terraform apply` workflow.
2. **[Infrastructure Verification Tests (`phase_3_testcases.md`)](./phase_3_testcases.md)**
   * Instructions on how to use the generated output endpoints to verify connectivity to your new databases and EKS cluster.

## 📂 Project Structure
```text
.
├── backend/                  # Spring Boot Application Source Code
├── frontend/                 # Next.js Application Source Code
├── ops/
│   ├── scripts/
│   │   └── setup_tf_state.sh # Bash helper to bootstrap the Terraform S3 remote backend
│   └── terraform/
│       └── aws/              # The Infrastructure configuration
│           └── main.tf       # Core IaC defining VPC, RDS, EKS, etc.
├── phase_3_testcases.md      # Verification procedures for provisioned outputs
└── phase_3_walkthrough.md    # Master Runbook for Terraform deployment
```

---
*Created as the Infrastructure as Code iteration for a DevOps Reference Architecture journey.*
