# 📦 Amazon-Like E-Commerce Platform (Phase 6d: Scan Reports & S3 Archiving)

## 🚀 Phase 6d Overview
This branch (`phase-6d-scanreports`) represents the **Compliance and Artifact Archiving** milestone of a production-grade e-commerce application. 

Building upon the Hybrid GitLab CI/CD pipeline from Phase 6c, this phase introduces a critical missing piece for enterprise compliance: **Permanent Record Keeping**. While CI/CD platforms usually delete job artifacts after a few days, security audits require historical proof of scans. 

To solve this, we use Terraform to provision a private Amazon S3 Bucket and configure IAM OIDC integration. The 10th stage of the GitLab pipeline now authenticates with AWS and pushes all vulnerability reports (IaC, Secrets, SCA, Container, DAST) and the compiled Java build artifact directly into long-term S3 storage before the pipeline finishes.

### 🛡 Archiving & Compliance Architecture
*   **Pipeline Orchestrator**: GitLab CI (Cloud SaaS)
*   **Storage Backend**: Amazon S3 (Private Bucket)
*   **Authentication**: AWS IAM Roles for Service Accounts (IRSA / OIDC via the EKS Node Group)
*   **Archived Artifacts**:
    *   `checkov-report.xml` (Terraform misconfigurations)
    *   `gitleaks-report.json` (Leaked secrets)
    *   `dependency-check.html` (Vulnerable open-source libraries)
    *   `trivy-report.txt` (Container OS vulnerabilities)
    *   `zap_report.html` (Dynamic runtime attacks)
    *   `backend.jar` (The compiled Java application)

```mermaid
graph TD
    %% Developers
    Dev([Developer]) -.->|git push| GitLabRepo
    
    %% GitLab Platform
    subgraph GitLabCloud ["GitLab Cloud"]
        GitLabRepo[(Git Repository)]
    end

    %% AWS Environment
    subgraph AWS ["AWS Cloud"]
        
        %% Long term storage
        S3[("Amazon S3 Bucket\n(Compliance Reports)")]
        
        %% EKS Cluster
        subgraph EKS ["Amazon Elastic Kubernetes Service (EKS)"]
            
            %% Security Toolchain
            subgraph SecNs ["Namespace: devsecops"]
                SonarQube[SonarQube Server]
            end
            
            %% Build Agents
            subgraph RunnerNs ["Namespace: gitlab-runner"]
                GitLabRunner[GitLab Runner Agent]
            end
        end
        
        IAM{{"IAM Node Role\n(S3 PutObject)"}}
    end

    %% Pipeline Flow
    GitLabRepo -->|Triggers| GitLabRunner
    
    %% 10-Stage Pipeline Flow
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
        S10[10. AWS CLI: Upload Reports]
        
        S1 --> S2 --> S3 --> S4 --> S5 --> S6 --> S7 --> S8 --> S9 --> S10
    end
    
    %% Execution Links
    GitLabRunner -.->|Executes| Pipeline
    GitLabRunner -.->|Assumes| IAM
    
    %% Upload Links
    S1 -.->|checkov.xml| S10
    S2 -.->|gitleaks.json| S10
    S3 -.->|backend.jar| S10
    S5 -.->|dependency-check.html| S10
    S7 -.->|trivy.txt| S10
    S9 -.->|zap.html| S10
    
    %% Final Push
    S10 ==>|aws s3 cp| S3

    %% Styling
    classDef user fill:#fff,stroke:#333,stroke-width:2px
    classDef glcloud fill:#292961,stroke:#e24329,color:white,stroke-width:2px
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef glrunner fill:#fc6d26,stroke:#e24329,color:white,stroke-width:2px
    classDef s3 fill:#388e3c,stroke:#2e7d32,color:white,stroke-width:2px,shape:cylinder
    classDef iam fill:#ed7d31,stroke:#c55a11,color:white,stroke-width:2px
    classDef pipe fill:#dcedc8,stroke:#689f38,color:black,stroke-width:1px
    
    class Dev user
    class GitLabCloud,GitLabRepo glcloud
    class AWS aws
    class GitLabRunner glrunner
    class S3 s3
    class IAM iam
    class S1,S2,S3,S4,S5,S6,S7,S8,S9,S10 pipe
```

## 🛠 S3 Archiving Setup

To provision the S3 bucket and execute the 10-stage pipeline:

1. **Provision Infrastructure**: Use Terraform in `ops/terraform/aws` to deploy the S3 bucket.
2. **Configure IAM**: Ensure your EKS Node Group IAM Role has `s3:PutObject` permissions.
3. **Set Variables**: Define the `$S3_BUCKET_NAME` variable in your GitLab CI/CD settings.
4. **Trigger Pipeline**: Push code to GitLab to watch the `upload_reports_job` securely archive your files.

## 📂 Project Structure
```text
.
├── .gitlab-ci.yml                 # 🦊 10-Stage Pipeline (Now includes `upload_reports_job`)
├── backend/                       # Source Code 
├── frontend/                      # Source Code
└── ops/
    ├── k8s/                  
    ├── scripts/
    └── terraform/
        └── aws/main.tf            # 🪣 IaC updated to provision the S3 Artifact Bucket
```

---
*Created as the S3 Artifact Archiving iteration for a DevOps Reference Architecture journey.*
