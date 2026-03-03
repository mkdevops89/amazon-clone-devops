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
            
            %% Availability Zone 1
            subgraph AZ1 ["Availability Zone 1 (us-east-1a)"]
                
                %% AZ1 Public Subnet (10.0.1.0/24)
                subgraph Public1 ["Public Subnet (10.0.1.0/24)"]
                    RT_Pub1[Route table]
                    ALB1[Application Load Balancer Node]
                    NAT1((VPC NAT gateway))
                end

                %% AZ1 Private Subnet (10.0.3.0/24)
                subgraph Private1 ["Private Subnet (10.0.3.0/24)"]
                    RT_Priv1[Route table]
                    EC2_App1[Amazon EC2<br>Frontend & Backend]
                    DB1[(MySQL DB instance)]
                    MQ1>RabbitMQ]
                end
            end
            
            %% Availability Zone 2
            subgraph AZ2 ["Availability Zone 2 (us-east-1b)"]
                
                %% Bastion placeholder 
                subgraph BastionSG ["bastion Host security group"]
                    Bastion[Bastion Host]
                end

                %% AZ2 Public Subnet (10.0.2.0/24)
                subgraph Public2 ["Public Subnet (10.0.2.0/24)"]
                    RT_Pub2[Route table]
                    ALB2[Application Load Balancer Node]
                    NAT2((VPC NAT gateway))
                end

                %% AZ2 Private Subnet (10.0.4.0/24)
                subgraph Private2 ["Private Subnet (10.0.4.0/24)"]
                    RT_Priv2[Route table]
                    EC2_App2[Amazon EC2<br>Frontend & Backend]
                    Cache2[CACHE<br>cache node]
                end
            end
        end
    end

    %% Ingress Traffic Flow
    Client --> IGW
    
    %% Route Table Connections to IGW
    IGW -.-> RT_Pub1
    IGW -.-> RT_Pub2
    
    %% Traffic flows to ALB
    RT_Pub1 --> ALB1
    RT_Pub2 --> ALB2
    
    %% Load Balancer to private instance flow
    ALB1 --> EC2_App1
    ALB2 --> EC2_App2
    
    %% Private Subnet traffic outbound to NAT
    EC2_App1 --> RT_Priv1
    EC2_App2 --> RT_Priv2
    RT_Priv1 -.-> NAT1
    RT_Priv2 -.-> NAT2
    
    %% Bastion Access
    IGW --> Bastion
    Bastion --> EC2_App1
    Bastion --> EC2_App2
    
    %% Data layer connections
    EC2_App1 --> DB1
    EC2_App2 --> Cache2
    EC2_App1 --> MQ1

    %% Styling to closely match image
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef green fill:#d4ecd3,stroke:#6ab165,stroke-width:2px,color:black
    classDef blue fill:#d2e5f3,stroke:#5b9bd5,stroke-width:2px,color:black
    classDef orange fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px
    classDef gateway fill:#ff9900,stroke:#e07b00,color:white,stroke-width:2px,shape:circle
    classDef db fill:#2173b8,stroke:#175182,color:white,stroke-width:2px
    
    class AZ1,AZ2 aws
    class Public1,Public2 green
    class Private1,Private2 blue
    class EC2_App1,EC2_App2,RT_Pub1,RT_Pub2,RT_Priv1,RT_Priv2,Bastion orange
    class IGW,NAT1,NAT2 gateway
    class DB1,Cache2,MQ1 db
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
