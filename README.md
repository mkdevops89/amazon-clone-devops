# 📦 Amazon-Like E-Commerce Platform (Phase 1: AWS Managed Services)

## 🚀 Phase 1 Overview
This branch (`phase-1-managed`) represents the **AWS Managed Services Phase** of a production-grade e-commerce application. 

Building upon the foundational manual EC2 deployment in Phase 0, this phase migrates the stateful data layer (Databases and Message Brokers) off of self-managed EC2 instances and onto AWS Managed Services (RDS, ElastiCache, Amazon MQ). 

This migration drastically reduces operational overhead, introduces automated backups, and improves the high-availability of the data tier without changing the underlying application code.

### 🏗 Architecture
*   **Frontend**: Next.js 14 (React) served via Node.js
*   **Backend**: Spring Boot 3.2 (Java 17) REST API
*   **Compute**: AWS EC2 Instances managed by Auto Scaling Groups (ASGs)
*   **Traffic routing**: AWS Application Load Balancer (ALB)
*   **Database layer**: 
    *   **Amazon RDS** (MySQL 8.0)
    *   **Amazon ElastiCache** (Redis)
    *   **Amazon MQ** (RabbitMQ)
*   **Security**: Strict AWS Security Group configurations and private subnets.

```mermaid
graph TD
    Client([Internet / Users])

    %% AWS Cloud
    subgraph AWSCloud ["AWS Cloud"]
        IGW((Internet gateway))
        
        %% Virtual Private Cloud
        subgraph VPC ["Virtual Private Cloud (10.0.0.0/16)"]
            
            %% ALB Spans Both Public Subnets
            ALB[Application Load Balancer]

            %% Availability Zone 1
            subgraph AZ1 ["Availability Zone 1 (us-east-1a)"]
                
                %% AZ1 Public Subnet (10.0.1.0/24)
                subgraph Public1 ["Public Subnet (10.0.1.0/24)"]
                    NAT1((NAT gateway))
                end

                %% AZ1 Private Subnet (10.0.3.0/24)
                subgraph Private1 ["Private Subnet (10.0.3.0/24)"]
                    EC2_Front1["Frontend EC2 (Next.js)"]
                    EC2_Back1["Backend EC2 (Spring Boot)"]
                    
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
                    %% ALB node is here, but logically represented above for both AZs
                    Placeholder[ ]
                    style Placeholder display:none;
                end

                %% AZ2 Private Subnet (10.0.4.0/24)
                subgraph Private2 ["Private Subnet (10.0.4.0/24)"]
                    EC2_Front2["Frontend EC2 (Next.js)"]
                    EC2_Back2["Backend EC2 (Spring Boot)"]
                end
            end
            
            %% Auto Scaling Groups
            subgraph ASGs ["Auto Scaling Groups"]
                direction LR
                ASG_Front((Frontend ASG))
                ASG_Back((Backend ASG))
            end
        end
    end

    %% Ingress Traffic Flow
    Client --> IGW
    IGW --> ALB
    
    %% ALB to ASG Routing
    ALB -->|HTTP 80 /| ASG_Front
    ALB -->|HTTP 80 /api/*| ASG_Back
    
    %% ASG logical grouping
    ASG_Front -.-> EC2_Front1
    ASG_Front -.-> EC2_Front2
    ASG_Back -.-> EC2_Back1
    ASG_Back -.-> EC2_Back2
    
    %% Internal API Routing 
    EC2_Front1 -.->|API Requests| ALB
    EC2_Front2 -.->|API Requests| ALB

    %% Data layer connections
    EC2_Back1 --> RDS
    EC2_Back1 --> ElastiCache
    EC2_Back1 --> AmazonMQ
    EC2_Back2 --> RDS
    EC2_Back2 --> ElastiCache
    EC2_Back2 --> AmazonMQ

    %% Outbound Traffic to NAT
    EC2_Front1 -.-> NAT1
    EC2_Front2 -.-> NAT1
    EC2_Back1 -.-> NAT1
    EC2_Back2 -.-> NAT1
    NAT1 -.-> IGW

    %% Styling to closely match image
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef green fill:#d4ecd3,stroke:#6ab165,stroke-width:2px,color:black
    classDef blue fill:#d2e5f3,stroke:#5b9bd5,stroke-width:2px,color:black
    classDef orange fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px
    classDef gateway fill:#ff9900,stroke:#e07b00,color:white,stroke-width:2px,shape:circle
    classDef db fill:#2173b8,stroke:#175182,color:white,stroke-width:2px
    classDef asg fill:#ffcc99,stroke:#ff9900,color:black,stroke-width:2px
    
    class AZ1,AZ2 aws
    class Public1,Public2 green
    class Private1,Private2 blue
    class EC2_Front1,EC2_Front2,EC2_Back1,EC2_Back2,ALB orange
    class IGW,NAT1 gateway
    class RDS,ElastiCache,AmazonMQ db
    class ASG_Front,ASG_Back asg
```


## 🛠 Managed Services Setup (Runbooks)

To update your infrastructure to use AWS Managed Services, execute these runbooks. These assume you have already completed the Phase 0 network foundation.

1. **[Network Configuration (`phase_0_network_config.md`)](./phase_0_network_config.md)**
   * VPC creation, Public/Private Subnets, Internet Gateways, and NAT Gateways (From Phase 0).
2. **[Security Groups (`phase_0_security_runbook.md`)](./phase_0_security_runbook.md)**
   * Defining strict ingress/egress rules between the different application tiers (From Phase 0).
3. **[Managed Data Layer Launch (`phase_0.5_managed_services_runbook.md`)](./phase_0.5_managed_services_runbook.md)**
   * Deploying Amazon RDS (MySQL), Amazon ElastiCache (Redis), and Amazon MQ (RabbitMQ) into private subnets.
4. **[Application Layer Launch (`phase_0.5_app_launch_runbook.md`)](./phase_0.5_app_launch_runbook.md)**
   * Updating Launch Templates and ASGs to point the Spring Boot backend to the newly provisioned Managed Service endpoints.

## 📂 Project Structure
```text
.
├── backend/                                   # Spring Boot Application Source Code
├── frontend/                                  # Next.js Application Source Code
├── ops/
│   └── scripts/                               # Helper setup scripts for EC2 instances
├── phase_0.5_app_launch_runbook.md            # Runbook: Updating App to use Managed Services
├── phase_0.5_managed_services_runbook.md      # Runbook: Launching RDS, ElastiCache, Amazon MQ
├── phase_0_network_config.md                  # Runbook: Setting up AWS VPC & Subnets
└── phase_0_security_runbook.md                # Runbook: Configuring Security Groups
```

---
*Created as the Managed Services iteration for a DevOps Reference Architecture journey.*
