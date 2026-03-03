# 📦 Amazon-Like E-Commerce Platform (Foundation: AWS EC2 ClickOps)

## 🚀 Phase 0 Overview
This branch (`phase-0-ec2`) represents the **Foundational Infrastructure Phase** of a production-grade e-commerce application. 

Instead of jumping straight to Kubernetes and automation, this phase focuses on understanding the underlying AWS primitives by manually building a robust, highly-available architecture using **AWS Console ClickOps and Auto Scaling Groups (ASGs)**.

This establishes a baseline for understanding VPCs, Security Groups, IAM roles, and Load Balancing before introducing infrastructure-as-code and orchestration in later phases.

### 🏗 Architecture
*   **Frontend**: Next.js 14 (React) served via Node.js
*   **Backend**: Spring Boot 3.2 (Java 17) REST API
*   **Compute**: AWS EC2 Instances managed by Auto Scaling Groups (ASGs)
*   **Traffic routing**: AWS Application Load Balancer (ALB)
*   **Database layer**: MySQL 8.0, Redis (Session/Cache), RabbitMQ (Messaging)
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
                    EC2_Front1[Frontend EC2 (Next.js)]
                    EC2_Back1[Backend EC2 (Spring Boot)]
                    
                    subgraph DataLayer ["Stateful Data Instances"]
                        direction TB
                        DB1[(MySQL 8.0)]
                        Cache1[(Redis)]
                        MQ1>RabbitMQ]
                    end
                end
            end
            
            %% Availability Zone 2
            subgraph AZ2 ["Availability Zone 2 (us-east-1b)"]

                %% AZ2 Public Subnet (10.0.2.0/24)
                subgraph Public2 ["Public Subnet (10.0.2.0/24)"]
                    %% ALB node is here, but logically represented above for both AZs
                    %% No NAT gateway here in Phase 0 runbook
                    Placeholder[ ]
                    style Placeholder display:none;
                end

                %% AZ2 Private Subnet (10.0.4.0/24)
                subgraph Private2 ["Private Subnet (10.0.4.0/24)"]
                    EC2_Front2[Frontend EC2 (Next.js)]
                    EC2_Back2[Backend EC2 (Spring Boot)]
                    %% No databases here (single AZ deployment for Phase 0)
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
    EC2_Back1 --> DB1
    EC2_Back1 --> Cache1
    EC2_Back1 --> MQ1
    EC2_Back2 --> DB1
    EC2_Back2 --> Cache1
    EC2_Back2 --> MQ1

    %% Outbound Traffic to NAT
    EC2_Front1 -.-> NAT1
    EC2_Front2 -.-> NAT1
    EC2_Back1 -.-> NAT1
    EC2_Back2 -.-> NAT1
    DB1 -.-> NAT1
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
    class DB1,Cache1,MQ1 db
    class ASG_Front,ASG_Back asg
```


## 🛠 Foundational Setup (Runbooks)

To deploy this infrastructure from scratch, execute the following runbooks in order. These contain step-by-step instructions and the required User Data bootstrap scripts for the EC2 instances.

1. **[Network Configuration (`phase_0_network_config.md`)](./phase_0_network_config.md)**
   * VPC creation, Public/Private Subnets, Internet Gateways, and NAT Gateways.
2. **[Security Groups (`phase_0_security_runbook.md`)](./phase_0_security_runbook.md)**
   * Defining strict ingress/egress rules between the different application tiers (ALB -> Frontend -> Backend -> Data layer).
3. **[Data Layer Launch (`phase_0_data_launch_runbook.md`)](./phase_0_data_launch_runbook.md)**
   * Deploying self-managed MySQL, Redis, and RabbitMQ EC2 instances into private subnets.
4. **[Application Layer Launch (`phase_0_app_launch_runbook.md`)](./phase_0_app_launch_runbook.md)**
   * Creating Launch Templates with User Data scripts.
   * Configuring Target Groups and Application Load Balancers.
   * Deploying the Frontend and Backend Auto Scaling Groups.

## 📂 Project Structure
```text
.
├── backend/                        # Spring Boot Application Source Code
├── frontend/                       # Next.js Application Source Code
├── ops/
│   ├── docker/                     # Basic Dockerfiles (Preparation for future phases)
│   └── scripts/                    # Helper setup scripts for EC2 instances
├── phase_0_app_launch_runbook.md   # Runbook: Launching Frontend/Backend ASGs
├── phase_0_data_launch_runbook.md  # Runbook: Launching Databases on EC2
├── phase_0_network_config.md       # Runbook: Setting up AWS VPC & Subnets
├── phase_0_security_runbook.md     # Runbook: Configuring Security Groups
└── docker-compose.yml              # Local orchestration for testing the code
```

## ⚡ Local Development

While this phase focuses on manual AWS deployment, you can spin up the application stack locally for development and testing using Docker Compose:

```bash
docker-compose up -d --build
```
*   **Frontend**: [http://localhost:3000](http://localhost:3000)
*   **Backend API**: [http://localhost:8080](http://localhost:8080)

---
*Created as the baseline infrastructure for a DevOps Reference Architecture journey.*
