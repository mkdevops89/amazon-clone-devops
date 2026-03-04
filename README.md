# 📦 Amazon-Like E-Commerce Platform (Phase 6a: GitHub Actions CI/CD & DevSecOps)

## 🚀 Phase 6a Overview
This branch (`phase-6a-githubactions`) represents the **Cloud-Native Continuous Integration & Continuous Deployment (CI/CD)** milestone of a production-grade e-commerce application. 

Building upon the robust AWS EKS infrastructure and secure routing established in previous phases, this phase introduces a fully automated, cloud-hosted pipeline using **GitHub Actions**. Every commit is subjected to a rigorous "Platinum" DevSecOps pipeline that automatically scans for vulnerabilities before packaging the application into Docker containers, pushing them to Elastic Container Registry (ECR), and deploying them to Kubernetes.

By embedding security checks directly into the developer workflow (Shift-Left), we ensure a highly secure, automated software supply chain.

### 🛡 DevSecOps CI/CD Architecture
*   **Pipeline Orchestration**: GitHub Actions
*   **Secret Scanning**: TruffleHog (Detects leaked API keys/credentials in commit history)
*   **Static Application Security Testing (SAST)**: SonarCloud (Analyzes code quality and bugs)
*   **Container Security**: Trivy (Scans the repository for Docker-related vulnerabilities)
*   **Dynamic Application Security Testing (DAST)**: OWASP ZAP (Scans the live deployed application)
*   **Deployment**: Automated `kubectl` applying manifests to Amazon EKS

```mermaid
graph TD
    %% Developer Action
    Dev([Developer]) -.->|git push| GitHubRepo

    %% GitHub Platform
    subgraph GitHub ["GitHub Cloud"]
        GitHubRepo[(Git Repository)]
        
        %% Pipeline Triggers
        GitHubRepo -->|Triggers| CI_Pipeline
        GitHubRepo -->|Triggers| CD_Pipeline
        
        %% CI Security Pipeline
        subgraph CI_Pipeline ["CI: DevSecOps Pipeline (.github/workflows/devsecops-ci.yaml)"]
            direction TB
            CheckoutCI[Actions Checkout]
            TruffleHog[TruffleHog: Secret Scanning]
            SonarCloud[SonarCloud: SAST & Code Quality]
            Trivy[Trivy: Container Security]
            
            CheckoutCI --> TruffleHog
            TruffleHog --> SonarCloud
            SonarCloud --> Trivy
        end
        
        %% CD Deployment Pipeline
        subgraph CD_Pipeline ["CD: Deployment Pipeline (.github/workflows/deploy-app.yaml)"]
            direction TB
            CheckoutCD[Actions Checkout]
            AWSLogin[Configure AWS Credentials]
            KubeConfig[Update EKS Kubeconfig]
            ECRLogin[Login to ECR]
            Deploy[Run deploy_k8s.sh]
            DAST[OWASP ZAP: DAST Baseline Scan]
            
            CheckoutCD --> AWSLogin
            AWSLogin --> KubeConfig
            KubeConfig --> ECRLogin
            ECRLogin --> Deploy
            Deploy --> DAST
        end
    end

    %% AWS Environment Deployment
    Deploy -.->|Build & Push Images| ECR[(Amazon ECR)]
    Deploy -.->|kubectl apply| EKS{{"Amazon EKS Cluster"}}
    
    %% Live Scanning
    DAST -.->|Scans Live App| ALB{{"Ingress (ALB)"}}
    ALB --> EKS

    %% Styling
    classDef user fill:#fff,stroke:#333,stroke-width:2px
    classDef github fill:#24292e,stroke:#fff,color:white,stroke-width:2px
    classDef action fill:#0366d6,stroke:#0366d6,color:white,stroke-width:2px
    classDef sec fill:#d73a49,stroke:#b31d28,color:white,stroke-width:2px
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    
    class Dev user
    class GitHub github
    class CheckoutCI,CheckoutCD,AWSLogin,KubeConfig,ECRLogin,Deploy action
    class TruffleHog,SonarCloud,Trivy,DAST sec
    class ECR,EKS,ALB aws
```

## ⚙️ CI/CD Setup (Runbooks)

To configure the GitHub Actions pipeline secrets and trigger your automated deployments, follow the Phase 6a Runbook.

1. **[GitHub Actions Walkthrough (`phase_6a_walkthrough.md`)](./phase_6a_walkthrough.md)**
   * Creating security tokens (SonarCloud).
   * Configuring AWS IAM Credentials as GitHub Action Secrets.
   * Triggering the CI (Security) and CD (Deploy) workflows.
2. **[CI/CD Verification Tests (`phase_6a_testcases.md`)](./phase_6a_testcases.md)**
   * Validating successful workflow executions.
   * Reviewing vulnerability reports from SonarCloud and ZAP.

## 📂 Project Structure
```text
.
├── .github/
│   └── workflows/
│       ├── deploy-app.yaml       # 🚀 CD Pipeline (Build -> Push -> Deploy -> DAST)
│       └── devsecops-ci.yaml     # 🛡 CI Pipeline (TruffleHog, SonarCloud, Trivy)
├── backend/                  # Source Code 
├── frontend/                 # Source Code
├── ops/
│   ├── k8s/                  # Kubernetes Manifests
│   └── scripts/
│       └── deploy_k8s.sh     # Executed automatically by the GitHub Action
├── phase_6a_testcases.md      # Verification procedures pipeline success
└── phase_6a_walkthrough.md    # Master Runbook for setting up GitHub Actions
```

---
*Created as the Cloud-Native CI/CD iteration for a DevOps Reference Architecture journey.*
