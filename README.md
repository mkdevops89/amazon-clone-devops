# 📦 Amazon-Like E-Commerce Platform (Phase 11: Advanced CI & GitOps)

## 🚀 Phase 11 Overview
This branch (`phase-11-gitops`) graduates the repository from "Basic Automation" to a **"Senior/Staff" Architecture**. 

We tackle the ultimate cloud-native maturity goal: **GitOps**. By replacing our static Kubernetes manifests with dynamic Helm Charts, and delegating the cluster synchronization to **ArgoCD**, the Git repository becomes the single source of truth for all environments. 

In parallel, we execute deep container hardening (running as non-root users, utilizing layered JAR caching) and expand our hybrid CI/CD toolchain to leverage GitHub Actions for deep application testing and Jenkins for GitOps automation.

### 🛠️ Key Architectural Shifts
1. **GitHub Actions (`ci.yaml`) - The DevSecOps Engine**
   * **The Role**: Executes rapid feedback loops. It compiles the Java/Next.js code, runs unit tests, executes Snyk dependency scanning, and performs Trivy docker image scanning (passing or failing the build before it ever reaches Staging).
2. **Jenkins - The GitOps Trigger**
   * **The Role**: The `Jenkinsfile` is now a deterministic GitOps orchestrator. It builds the Docker images, tags them with the exact Git commit SHA (e.g., `amazon-backend:a1b2c3d`), pushes them to ECR, and then *automatically commits* that new SHA tag into the `values.yaml` file of the Helm Chart.
3. **ArgoCD - The GitOps Controller**
   * **The Role**: An ArgoCD server runs inside the EKS cluster, constantly watching the `ops/helm/amazon-app/` directory in GitHub. When Jenkins pushes a new image tag to the `values.yaml` file, ArgoCD detects the drift and automatically synchronizes the cluster to match the exact state defined in Git.
   * **Features**: State Persistence (Redis PVC), Custom Route53 DNS (`argocd.devcloudproject.com`), and Prometheus metric scraping.
4. **Helmification & Docker Hardening**
   * **Helm**: Replaced static YAMLs with a scalable `amazon-app` Helm Chart, allowing infinite environment deployments (Dev, Staging, Prod) purely by supplying different variables.
   * **Docker**: Refactored the `Dockerfile`s to run as low-privilege `spring` and `nextjs` users. Enabled Maven Layered JARs to aggressively cache 400MB+ dependencies.
5. **FinOps Observability Restoration (`cost-exporter`)**
   * **The Fix**: The custom Python `cost-exporter` service (originally built in Phase 8.5 to scrape the AWS Billing API and feed the Grafana `finops.json` dashboard) was accidentally lost during a previous phase transition. This branch explicitly restored the service and its accompanying Kubernetes ServiceMonitors to ensure the FinOps dashboard remains operational under the new GitOps architecture.

```mermaid
graph TD
    %% Dev Flow
    Dev[Developer] -->|Push Code| GithubRepo[GitHub Repository]
    GithubRepo -->|Trigger| GHA[GitHub Actions\n(ci.yaml)]
    
    %% CI Layer
    subgraph CI ["Continuous Integration (CI)"]
        GHA -.->|Run| Tests[Unit Tests & Snyk]
        GHA -.->|Run| Security[Trivy & DAST]
        Jenkins[Jenkins Pipeline\n(Jenkinsfile)]
    end
    
    GithubRepo -->|Trigger| Jenkins
    Jenkins -->|1. Build & Tag\n(Git SHA)| ECR[AWS ECR]
    Jenkins -->|2. Git Commit\n(values.yaml)| GithubRepo
    
    %% CD / GitOps Layer
    subgraph GitOps ["Continuous Deployment (GitOps)"]
        Argo[ArgoCD Controller]
    end
    
    Argo -.->|3. Watch Changes| GithubRepo
    Argo -->|4. Sync Cluster| EKS[EKS Cluster\n(Helm Chart Deployment)]
    
    %% Styling
    classDef aws fill:#f9f9f9,stroke:#666,stroke-dasharray: 5 5
    classDef ci fill:#e1f5fe,stroke:#0288d1,color:black,stroke-width:1px
    classDef cd fill:#e8f5e9,stroke:#388e3c,color:black,stroke-width:1px
    
    class ECR,EKS aws
    class GHA,Jenkins,Tests,Security ci
    class Argo cd
```

## 📂 Project Structure
```text
.
├── .github/workflows/             # 🐙 GitHub Actions Pipelines (DevSecOps Scans & Unit Tests)
├── .gitlab-ci.yml                 # 🦊 GitLab CI Pipeline (Legacy UI/API Deployments)
├── Jenkinsfile                    # 🕴️ Jenkins Pipeline (GitOps Automation & SHA Tagging)
├── backend/                       # ✅ Spring Boot App (Layered JARs & Non-Root Docker)
├── frontend/                      # ✅ React App (Next.js Standalone Build & Non-Root Docker)
└── ops/
    ├── cost-exporter/             # 💸 Python FinOps Exporter (Restored for AWS Billing Metrics)
    ├── helm/                      # ☸️ The Portable Amazon-App Helm Chart
    ├── k8s/                       
    │   └── argocd-app.yaml        # 🐙 ArgoCD Application definition manifest
    └── scripts/                   
        └── deploy_k8s.sh          # Legacy deployment script (Deprecating in favor of ArgoCD)
```

---
*Created as the Advanced CI & GitOps iteration for a DevOps Reference Architecture journey.*
