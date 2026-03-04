# 📦 Amazon-Like E-Commerce Platform (Phase 8: Advanced FinOps & Optimization)

## 🚀 Phase 8 Overview
This branch (`phase-8-finops`) represents the **Advanced Financial Operations (FinOps) and Optimization** milestone of our production-grade e-commerce application. 

As cloud infrastructure scales, costs can rapidly spiral out of control. This phase focuses entirely on cost reduction, workload optimization, and budget safety using a combination of Terraform infrastructure changes and Kubernetes scheduling intelligence.

By splitting our single monolithic EKS Node Group into a **Hybrid Architecture** (combining reliable On-Demand "Critical" nodes with cheap, ephemeral "Spot" nodes) and pinning our stateful applications to the critical tier, we dramatically lower our monthly AWS bill without sacrificing the stability of our CI/CD toolchain.

### 💸 FinOps Architecture & Features
1. **Hybrid EKS Node Groups (Spot + On-Demand)**
   * **Technology**: AWS EKS, EC2 Spot Instances, Terraform.
   * **Purpose**: Provisions a "Critical" Node Group (On-Demand) for stable databases and CI/CD tools, alongside a "Spot" Node Group (excess AWS capacity at up to 90% discount) for stateless application replicas.
2. **Intelligent Kubernetes Scheduling**
   * **Technology**: Kubernetes `nodeSelector` and `nodeAffinity`.
   * **Purpose**: Modifies the `jenkins.yaml`, `nexus.yaml`, and `sonarqube.yaml` manifests to explicitly bind these stateful applications to the `intent=critical` nodes, preventing them from being evicted when AWS reclaims Spot instances.
3. **Automated Cost Protection (AWS Budgets)**
   * **Technology**: AWS Budgets (via Terraform).
   * **Purpose**: Acts as a financial safety net native to AWS. If the projected monthly cost of the environment exceeds the defined limit ($50), an alert is immediately triggered.
4. **Right-Sizing AI & Memory Pressure Checks**
   * **Technology**: Go (Custom CLI), Python (AWS Lambda).
   * **Purpose**: Enhances the Phase 7 automation scripts. The `ops-check` CLI now actively detects Memory and Disk pressure across the cluster, while the `cost_optimizer` Lambda analyzes CPU utilization trends to recommend EC2 instance downgrades.

```mermaid
graph TD
    %% AWS Environment
    subgraph AWS ["Amazon Web Services (AWS)"]
        
        %% AWS Billing
        Budget["AWS Budget<br/>Alert limit: $50"]
        
        %% EKS Cluster
        subgraph EKS ["AWS Elastic Kubernetes Service (EKS)"]
            
            %% Critical Tier
            subgraph CriticalNodes ["Critical Node Group (On-Demand)"]
                label1["Label: intent=critical"]
                Jenkins[Jenkins Controller]
                Nexus[Sonatype Nexus]
                SonarQube[SonarQube Server]
            end
            
            %% Spot Tier
            subgraph SpotNodes ["Spot Node Group (Ephemeral/Cheap)"]
                label2["Label: lifecycle=Ec2Spot"]
                Backend[Amazon Backend Pods]
                Frontend[Amazon Frontend Pods]
            end
        end
    end

    %% Scheduling Rules
    Jenkins -.->|nodeSelector| label1
    Nexus -.->|nodeSelector| label1
    SonarQube -.->|nodeSelector| label1
    Backend -.->|Scheduled by K8s| label2
    Frontend -.->|Scheduled by K8s| label2

    %% Observation Tools
    subgraph Tools ["FinOps Observation Tooling"]
        CostLambda["Python Cost Optimizer Lambda<br/>(Right-Sizing Intelligence)"]
        GoCLI["Go Ops-Check CLI<br/>(Checks Memory/Disk Pressure)"]
    end

    CostLambda -.->|Analyzes CPU Metrics| Budget
    GoCLI -.->|Queries Kube API| Jenkins
    label2 -.->|Incurs Cost| Budget

    %% Styling
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef spot fill:#dcedc8,stroke:#689f38,color:black,stroke-width:2px
    classDef critical fill:#ffcc80,stroke:#e65100,color:black,stroke-width:2px
    classDef app fill:#e1f5fe,stroke:#0288d1,color:black,stroke-width:1px
    classDef billing fill:#4caf50,stroke:#1b5e20,color:white,stroke-width:2px
    classDef tool fill:#8e44ad,stroke:#5e3370,color:white,stroke-width:2px
    
    class label2 spot
    class label1 critical
    class Jenkins,Nexus,SonarQube,Backend,Frontend app
    class Budget billing
    class CostLambda,GoCLI tool
```

## 🛠 FinOps Setup (Runbooks)

To provision the Hybrid Spot Architecture, enforce the Kubernetes scheduling constraints, and run the new optimization tooling, follow the Phase 8 Execution Guide.

1. **[Advanced FinOps Walkthrough (`phase_8_walkthrough.md`)](./phase_8_walkthrough.md)**
   * Applying the updated Terraform to split the EKS Node Groups and create the AWS Budget.
   * Applying the updated Kubernetes manifests to pin stateful apps to the Critical Nodes.
   * Verifying the cluster's mixed capacity architecture using `kubectl get nodes`.

## 📂 Project Structure
```text
.
├── backend/                       # Source Code 
├── frontend/                      # Source Code
├── ops/
│   ├── cli/
│   │   └── ops-check/             # Enhanced Go CLI (Memory/Disk pressure checks)
│   ├── k8s/                       
│   │   ├── jenkins/               # Jenkins Manifests (Added nodeSelector)
│   │   ├── nexus/                 # Nexus Manifests (Added nodeSelector)
│   │   └── sonarqube/             # SonarQube Manifests (Added nodeSelector)
│   ├── lambda/
│   │   └── cost_optimizer/        # Enhanced Python Lambda (Right-Sizing AI logic)
│   └── terraform/
│       └── aws/                   # 🪣 IaC updated for Spot Nodes and Budgets
└── phase_8_walkthrough.md         # Master Runbook for Hybrid Architecture & Cost Controls
```

---
*Created as the Advanced FinOps and Workload Optimization iteration for a DevOps Reference Architecture journey.*
