# 📦 Amazon-Like E-Commerce Platform (Phase 6c: GitLab CI & DevSecOps)

## 🚀 Phase 6c Overview
This branch (`phase-6c-gitlab`) represents the **Hybrid DevSecOps CI/CD** milestone of a production-grade e-commerce application. 

In this phase, we migrate our CI/CD strategy to leverage **GitLab CI** combined with a **Self-Hosted Kubernetes Runner**. By using GitLab's cloud-hosted UI for pipeline orchestration but executing the actual builds securely inside our own AWS EKS cluster, we achieve a highly secure, zero-queue, and cost-effective deployment engine.

Additionally, this phase introduces a self-hosted **SonarQube** server to perform deep Static Application Security Testing (SAST) and code quality gating. The comprehensive 9-stage pipeline ensures that infrastructure, secrets, dependencies, containers, and live runtime environments are all rigorously scanned before and after deployment.

### 🦊 Hybrid DevSecOps Architecture
*   **Pipeline Orchestrator**: GitLab CI (Cloud SaaS)
*   **Build Executor**: Self-Hosted GitLab Runner (Deployed in EKS)
*   **Static Application Security Testing (SAST)**: Self-Hosted SonarQube (Deployed in EKS with persistent EBS storage)
*   **Infrastructure as Code (IaC) Scanning**: Checkov
*   **Secret Scanning**: Gitleaks
*   **Software Composition Analysis (SCA)**: OWASP Dependency-Check (NVD API integrated)
*   **Container Build Engine**: Kaniko (Daemonless, unprivileged image builder)
*   **Container Security**: Trivy
*   **Dynamic Application Security Testing (DAST)**: OWASP ZAP

```mermaid
graph TD
    %% Developers
    Dev([Developer]) -.->|git push| GitLabRepo
    
    %% GitLab.com Platform
    subgraph GitLabCloud ["GitLab Cloud / SaaS"]
        GitLabRepo[(Git Repository)]
        CI_Coordinator[CI/CD Orchestrator]
        
        GitLabRepo --> CI_Coordinator
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
            
            %% Security Toolchain
            subgraph SecNs ["Namespace: devsecops"]
                SonarQube[SonarQube Server]
                EBS_Sonar[(EBS Volume: sonar-data)]
                SonarQube --- EBS_Sonar
            end
            
            %% Build Agents
            subgraph RunnerNs ["Namespace: gitlab-runner"]
                GitLabRunner[GitLab Runner Agent]
            end
        end
    end

    %% Hybrid Communication
    CI_Coordinator -.->|Assigns Job| GitLabRunner
    
    %% 9-Stage Pipeline Flow
    subgraph Pipeline ["GitLab CI Pipeline (.gitlab-ci.yml)"]
        direction TB
        S1[1. Checkov: IaC Scan]
        S2[2. Gitleaks: Secret Scan]
        S3[3. Maven Build]
        S4[4. SonarQube: Code Quality]
        S5[5. OWASP Dep-Check: SCA]
        S6[6. Kaniko: Build/Push Docker]
        S7[7. Trivy: Container Scan]
        S8[8. kubectl apply: Deploy]
        S9[9. OWASP ZAP: DAST]
        
        S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8 --> S9
    end
    
    %% Execution Links
    GitLabRunner -.->|Executes Pipeline| Pipeline
    S4 -.->|Publishes Report| SonarQube
    S6 -.->|Pushes Image| ECR[(Amazon ECR)]
    S8 -.->|Updates Manifests| AppSvc
    S9 -.->|Attacks Live App| ALB
    ALB --> EKS_Workloads

    %% Styling
    classDef user fill:#fff,stroke:#333,stroke-width:2px
    classDef glcloud fill:#292961,stroke:#e24329,color:white,stroke-width:2px
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef k8s fill:#e1f5fe,stroke:#0288d1,color:black,stroke-width:1px
    classDef glrunner fill:#fc6d26,stroke:#e24329,color:white,stroke-width:2px
    classDef sonarqube fill:#4b9fd5,stroke:#265f80,color:white,stroke-width:2px
    classDef pipe fill:#dcedc8,stroke:#689f38,color:black,stroke-width:1px
    
    class Dev user
    class GitLabCloud,GitLabRepo,CI_Coordinator glcloud
    class AWS,ALB aws
    class AppNs k8s
    class GitLabRunner glrunner
    class SonarQube sonarqube
    class S1,S2,S3,S4,S5,S6,S7,S8,S9 pipe
```

## 🛠 Hybrid CI/CD Setup (Runbooks)

To provision the infrastructure, register your private GitLab Runner, and execute the 9-stage pipeline, follow the Phase 6c Runbooks.

1. **[GitLab Hybrid Walkthrough (`phase_6c_walkthrough.md`)](./phase_6c_walkthrough.md)**
   * Deploying SonarQube with persistent EBS volumes.
   * Accessing SonarQube and generating quality gate tokens.
   * Registering a self-hosted GitLab Runner in EKS.
   * Configuring `.gitlab-ci.yml` pipeline variables (AWS Credentials, NVD API, Tokens).
2. **[CI/CD Verification Tests (`phase_6c_testcases.md`)](./phase_6c_testcases.md)**
   * Validating successful execution of all 9 pipeline stages.
   * Downloading and auditing job artifacts (`checkov.xml`, `gitleaks.json`, `zap.html`).

## 📂 Project Structure
```text
.
├── .gitlab-ci.yml            # 🦊 9-Stage GitLab Pipeline Definition
├── .gitleaksignore           # Git history exceptions for secret scanning
├── backend/                  # Source Code 
├── frontend/                 # Source Code
├── ops/
│   ├── k8s/                  
│   │   ├── gitlab/           # K8s Manifests (GitLab Runner Deployment, RBAC)
│   │   ├── sonarqube/        # K8s Manifests (SonarQube Deployment, PVC, Svc, Ingress)
│   │   └── ...               # App manifests
│   └── scripts/
│       └── deploy_k8s.sh     # Executed automatically by GitLab CI
├── phase_6c_testcases.md     # Verification procedures for pipeline success
└── phase_6c_walkthrough.md   # Master Runbook for Hybrid GitLab CI/CD setup
```

---
*Created as the Hybrid GitLab CI/CD iteration for a DevOps Reference Architecture journey.*
