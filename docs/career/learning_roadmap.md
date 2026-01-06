# 🗺️ DevOps Project Learning Roadmap

This roadmap is designed to take you from a local development environment to an Enterprise-Grade Cloud Native Architect.

## 🟢 Phase 1: Manual Provisioning (The "Hard Way")
*   **Goal**: Understand the components by installing them manually.
*   **Tech**: Vagrant or AWS EC2 (Free Tier).
*   **Task**: Manually SSH into servers and install Java, MySQL, RabbitMQ, Redis, Nginx.
*   **Outcome**: You understand *what* the automation needs to do.

## 🟢 Phase 2: Containerization (Docker)
*   **Goal**: Solve "It works on my machine".
*   **Tech**: Docker, Docker Compose.
*   **Task**: Write `Dockerfile` for Backend/Frontend. Create `docker-compose.yml` to spin up the whole stack with one command.
*   **Outcome**: Portable application stack.

## 🟠 Phase 3: Infrastructure as Code (Terraform)
*   **Goal**: Automate the creation of Cloud Resources.
*   **Tech**: Terraform, AWS (VPC, EKS, RDS, ElastiCache).
*   **Task**: Write `.tf` files to provision a VPC, Public/Private Subnets, and an EKS Cluster.
*   **Outcome**: One command (`terraform apply`) creates your entire AWS Env.

## 🟣 Phase 4: CI Pipeline (Jenkins/GitHub Actions)
*   **Goal**: Automate Build and Test.
*   **Tech**: Jenkins (Groovy) or GitHub Actions (YAML).
*   **Task**: Create a pipeline that triggers on Git Push -> Builds App -> Runs Tests -> Uploads Artifacts.
*   **Outcome**: No more manual builds.

## 🔒 Phase 5: DevSecOps (Security)
*   **Goal**: Shift Security Left.
*   **Tech**: Snyk (SCA), OWASP ZAP (DAST), Trivy (Container Scan), SonarQube (SAST).
*   **Task**: Add security gates to your Pipeline. Fail the build if vulnerabilities are found in code, dependencies, or runtime.
*   **Outcome**: Secure by design.

## ☸️ Phase 6: Kubernetes Orchestration
*   **Goal**: Run containers in production.
*   **Tech**: EKS, kubectl.
*   **Task**: Write K8s Manifests (Deployment, Service, ConfigMap, Secret). Deploy App to EKS.
*   **Outcome**: scalable, self-healing application.

## 🔄 Phase 7: GitOps (ArgoCD)
*   **Goal**: Continuous Deployment.
*   **Tech**: ArgoCD, Helm Charts.
*   **Task**: Install ArgoCD. Connect it to your Git Repo. Let it sync your K8s manifests automatically.
*   **Outcome**: "ClickOps" is gone. Git is the source of truth.

## ⚙️ Phase 8: Configuration Management (Ansible)
*   **Goal**: Manage what's *inside* the VMs (if not using K8s).
*   **Tech**: Ansible.
*   **Task**: Write Playbooks to patch servers, install agents, and configure OS level settings.
*   **Outcome**: Consistent server configurations.

## 📊 Phase 9: Observability (Monitoring)
*   **Goal**: Visualization and Alerting.
*   **Tech**: Prometheus, Grafana.
*   **Task**: Install Prometheus (Scrape metrics). Create Grafana Dashboards (Visualize CPU, Memory, Request Count).
*   **Outcome**: You know when something breaks before the users do.

## 📦 Phase 10: Immutable Infrastructure (Packer)
*   **Goal**: Speed up scaling and remove configuration drift.
*   **Tech**: HashiCorp Packer.
*   **Task**: Use Packer to build an Amazon Machine Image (AMI) with Java, Nginx, and dependencies pre-baked.
*   **Outcome**: Instance launch time drops from minutes to seconds.

## 🔐 Phase 11: Advanced Secret Management (Vault)
*   **Goal**: Eliminate long-lived credentials.
*   **Tech**: HashiCorp Vault.
*   **Task**: Deploy Vault on K8s. Configure "Dynamic Secrets" for MySQL (Vault creates a new DB user for every App pod request).
*   **Outcome**: If a secret leaks, it expires/rotates automatically. Zero Trust Security.

## 🪵 Phase 12: Centralized Logging (ELK Stack)
*   **Goal**: Debugging complex distributed systems.
*   **Tech**: Elasticsearch, Logstash, Kibana (or Fluentd).
*   **Task**: Deploy EFK Stack. Configure Fluentd to ship container logs to Elasticsearch. Visualize logs in Kibana.
*   **Outcome**: Full text search of error logs across all 50+ pods in the cluster.

## 🕸️ Phase 13: Service Mesh (Istio)
*   **Goal**: Advanced Traffic Management & Zero Trust.
*   **Tech**: Istio or Linkerd.
*   **Task**: Inject Sidecar proxies. Enable mTLS. Configure Traffic Splitting (Canary Deploy).
*   **Outcome**: Encrypted traffic and safe rollouts.

## 🏗️ Phase 14: Advanced IaC (Terragrunt)
*   **Goal**: Scale Terraform for multiple environments (DRY).
*   **Tech**: Terragrunt.
*   **Task**: Refactor monolithic Terraform into atomic modules. Use Terragrunt to manage state locking and backend configuration automatically.
*   **Outcome**: Deploy `dev`, `stage`, and `prod` environments with minimal code duplication.
