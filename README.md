# 📦 Amazon-Like E-Commerce Platform (Phase 6b: Enterprise CI/CD & DevSecOps)

## 🚀 Phase 6b Overview
This branch (`phase-6b-jenkins`) represents the **Enterprise Self-Hosted CI/CD** milestone of a production-grade e-commerce application. 

Diverging from the cloud-native approach of Phase 6a, this phase simulates a strict enterprise environment by deploying the entire DevSecOps toolchain—including a **Jenkins** orchestration server and a **Sonatype Nexus** artifact repository—directly onto our AWS EKS cluster. 

By leveraging the AWS EBS CSI driver and dynamic volume provisioning (`gp3`), we ensure our CI/CD state is persistent and reliable. We then wire up automated GitHub Webhooks to trigger our `Jenkinsfile` pipeline, providing a secure, end-to-end continuous deployment framework that is entirely self-hosted and privately managed.

### 🏯 Enterprise DevSecOps Architecture
*   **Pipeline Orchestrator**: Self-hosted Jenkins (deployed via K8s Stateful/Deployment manifests)
*   **Artifact Repository**: Self-hosted Sonatype Nexus (Maven & Docker repositories)
*   **Persistent Storage**: AWS Elastic Block Store (EBS) managed via the EBS CSI Driver
*   **Vulnerability Scanning**: OWASP Dependency-Check (NVD API integrated)
*   **Automation Triggers**: GitHub Webhooks & SCM Polling
*   **Notifications**: Real-time Slack Webhook alerts for build statuses
*   **Ingress Routing**: Shared AWS Application Load Balancer (ALB) across App, Grafana, Jenkins, and Nexus

```mermaid
graph TD
    %% Developers
    Dev([Developer]) -.->|git push| GitHubRepo
    
    %% GitHub Platform
    subgraph GitHub ["GitHub"]
        GitHubRepo[(Git Repository)]
        Webhook((Push Webhook))
        
        GitHubRepo -->|Triggers| Webhook
    end

    %% AWS Environment
    subgraph AWS ["AWS Elastic Kubernetes Service (EKS)"]
        
        %% Shared ALB
        ALB{{"Application Load Balancer (Shared)"}}
        
        %% Kubernetes Workloads
        subgraph EKS_Workloads ["Kubernetes Workloads"]
            
            %% Application
            subgraph AppNs ["Namespace: default"]
                AppSvc[Frontend & Backend Services]
            end
            
            %% CI/CD Toolchain
            subgraph JenkinsNs ["Namespace: devsecops"]
                Jenkins[Jenkins Controller]
                Nexus[Sonatype Nexus Repository]
                
                %% Storage
                EBS_Jenkins[(EBS Volume: jenkins_home)]
                EBS_Nexus[(EBS Volume: nexus-data)]
                EBS_NVD[(EBS Volume: nvd-cache)]
                
                Jenkins --- EBS_Jenkins
                Jenkins --- EBS_NVD
                Nexus --- EBS_Nexus
            end
        end
    end

    %% Webhook triggering Jenkins
    Webhook -.->|HTTP POST| ALB
    ALB -->|/github-webhook/| Jenkins
    
    %% Jenkins Pipeline Flow
    subgraph Pipeline ["Jenkins Pipeline Execution"]
        direction LR
        Checkout[Checkout Code]
        Scan[OWASP Dep-Check]
        Build[Maven Build]
        PushNexus[Push to Nexus]
        Deploy[Deploy to EKS]
        SlackAlert[Slack Notification]
        
        Checkout --> Scan
        Scan --> Build
        Build --> PushNexus
        PushNexus --> Deploy
        Deploy --> SlackAlert
    end
    
    %% Pipeline execution link
    Jenkins -.->|Spawns Agent Pod| Pipeline
    Deploy -.->|kubectl apply| AppSvc
    PushNexus -.->|HTTP POST| Nexus

    %% Styling
    classDef user fill:#fff,stroke:#333,stroke-width:2px
    classDef github fill:#24292e,stroke:#fff,color:white,stroke-width:2px
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef jenkins fill:#d32f2f,stroke:#b71c1c,color:white,stroke-width:2px
    classDef nexus fill:#1b5e20,stroke:#2e7d32,color:white,stroke-width:2px
    classDef ebs fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px,shape:cylinder
    classDef pipe fill:#e1f5fe,stroke:#0288d1,color:black,stroke-width:1px
    
    class Dev user
    class GitHub,GitHubRepo,Webhook github
    class ALB,EKS_Workloads aws
    class Jenkins,Pipeline jenkins
    class Nexus nexus
    class EBS_Jenkins,EBS_Nexus,EBS_NVD ebs
    class Checkout,Scan,Build,PushNexus,Deploy pipe
```

## 🛠 Self-Hosted Setup (Runbooks)

To provision the infrastructure and configure the Jenkins pipelines, follow the Phase 6b Runbooks.

1. **[Enterprise Setup Walkthrough (`phase_6b_walkthrough.md`)](./phase_6b_walkthrough.md)**
   * Installing the AWS EBS CSI Driver for persistent volume mounting.
   * Deploying Jenkins and Nexus to the `devsecops` namespace.
   * Unlocking the CI/CD portals and configuring Jenkins Kubernetes Cloud agents.
   * Executing the `Jenkinsfile` pipeline and configuring GitHub Webhooks.

## 📂 Project Structure
```text
.
├── Jenkinsfile               # 🏯 Jenkins Pipeline Script (Build, Scan, Deploy)
├── backend/                  # Source Code 
├── frontend/                 # Source Code
├── ops/
│   ├── k8s/                  
│   │   ├── jenkins/          # K8s Manifests (Jenkins Deployment, PVC, Svc)
│   │   ├── nexus/            # K8s Manifests (Nexus Deployment, PVC, Svc)
│   │   └── ...               # App manifests
│   └── scripts/
│       ├── install_ebs_driver.sh  # Bootstraps AWS EBS CSI Driver
│       └── deploy_k8s.sh          # Executed automatically by Jenkins
└── phase_6b_walkthrough.md   # Master Runbook for self-hosted enterprise CI/CD
```

---
*Created as the Enterprise Jenkins CI/CD iteration for a DevOps Reference Architecture journey.*
