# 📦 Amazon-Like E-Commerce Platform (Phase 12: Ansible Configuration & Auditing)

## 🚀 Phase 12 Overview
This branch (`phase-12-ansible`) introduces **Ansible** to the DevOps toolchain, showcasing how Configuration Management evolves in a modern cloud-native architecture.

Rather than using Ansible to forcefully mutate container state (which is an anti-pattern when using Kubernetes and ArgoCD), we demonstrate two distinct tracks of infrastructure management and compliance auditing:

1. **Track A (The Pet)**: Managing traditional static infrastructure (like our secure EC2 Bastion host).
2. **Track B (The Cattle)**: Utilizing AWS Dynamic Inventory to actively audit GitOps deliverables and auto-discover ephemeral EKS nodes.

### 🛠️ Key Architectural Inclusions
1. **AWS EC2 Dynamic Inventory (`aws_ec2.yaml`)**
   * **The Capability**: Instead of maintaining a hardcoded list of IP addresses in a static `hosts` file, Ansible uses the AWS API (via `boto3`) to dynamically query our cloud account. 
   * **The Polish**: Ansible automatically targets instances based purely on their Terraform Tags (e.g., `tag_Name_ansible_bastion` or `tag_eks_cluster_name_amazon_cluster`), meaning the inventory perfectly scales up alongside the EKS cluster.
2. **Traditional Configuration Management (Track A)**
   * **The Use Case**: The `admin-server.yaml` playbook targets our dedicated EC2 Bastion host. 
   * **The Execution**: It locks down the host by installing `fail2ban`, explicitly denying `Root` SSH access over the network, configuring a secure custom `admin` user, and bootstrapping necessary DevOps CLIs (like `kubectl`, `helm`, and `docker`).
3. **Dynamic GitOps Auditing (Track B)**
   * **The Concept**: Since ArgoCD handles deploying the application code, we pivot Ansible into an external "Audit Engine".
   * **The Execution**: The `health-checks.yaml` playbook runs locally and fires HTTP tests against the live API, Frontend, and Jenkins instances to definitively prove that the GitOps pipeline delivered the expected code to the public endpoints.
4. **EKS Node Compliance (Track B)**
   * **The Use Case**: The `eks-audit.yaml` playbook targets the dynamically discovered EKS worker nodes to ensure AWS management and security agents (like `amazon-ssm-agent` and `amazon-inspector-agent`) are actively running on the underlying hardware.

## 📂 Project Structure
```text
.
├── .github/workflows/             # 🐙 GitHub Actions Pipelines (DevSecOps Scans & Unit Tests)
├── .gitlab-ci.yml                 # 🦊 GitLab CI Pipeline (Legacy Deployments)
├── Jenkinsfile                    # 🕴️ Jenkins Pipeline (GitOps Image Building & Helm Commits)
├── backend/                       # ✅ Spring Boot App 
├── frontend/                      # ✅ React App 
└── ops/
    ├── ansible/                   # ⚙️ Ansible Configuration Management
    │   ├── inventory/             
    │   │   └── aws_ec2.yaml       # Dynamic AWS Account querying plugin
    │   └── playbooks/
    │       ├── admin-server.yaml  # Configures & secures the EC2 Bastion host
    │       ├── eks-audit.yaml     # Audits the AWS EKS Worker Nodes
    │       └── health-checks.yaml # HTTP tester for public GitOps endpoints
    ├── helm/                      # ☸️ The Portable Amazon-App Helm Chart
    ├── k8s/                       # 🐙 ArgoCD Application definition manifest
    └── terraform/                 # 🏗️ Terraform (Now provisions the EC2 Bastion Host)
```

---
*Created as the Configuration Management iteration for a DevOps Reference Architecture journey.*
