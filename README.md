# 📦 Amazon-Like E-Commerce Platform (Phase 13: Centralized Logging)

## 🚀 Phase 13 Overview
This branch (`phase-13-elk`) implements **Production-Grade Centralized Logging** by introducing the ELK Stack (Elasticsearch, Logstash/Filebeat, Kibana) via GitOps.

Because Docker containers and Kubernetes pods are ephemeral by design, relying on node-level storage or `kubectl logs` is a major anti-pattern. If a node scales down, its logs are permanently lost.

In this phase, we solve the "ephemeral data" problem by decoupling log storage from compute. We deploy an agent to automatically vacuum up every text log generated across the EKS cluster and ship them to a highly available, searchable backend database. 

### 🛠️ Key Architectural Inclusions
1. **Elasticsearch (The Database)**
   * **The Role**: Acts as the stateful, searchable backend database for all infrastructure and application logs. Deployed with a 10GB AWS EBS persistent volume to survive pod restarts.
2. **Filebeat (The Log Vacuum)**
   * **The Role**: Deployed as a Kubernetes `DaemonSet`. This guarantees that exactly one Filebeat agent is running silently on every single EKS worker node. 
   * **The Execution**: Filebeat automatically mounts the node's `/var/log/containers/` directory, tails the output of every container in real-time, formats it, and ships it directly into Elasticsearch.
3. **Kibana (The UI)**
   * **The Role**: The visualization dashboard used by developers and operations teams to search, filter, and alert on log data natively.
   * **The Execution**: Exposed securely over HTTPS at `kibana.devcloudproject.com`. It shares the exact same AWS Application Load Balancer (ALB) as Grafana and Jenkins via Ingress group annotations, dramatically reducing cloud infrastructure costs.
4. **Structured JSON Application Logging**
   * **The Role**: By default, applications like Spring Boot emit unstructured, multi-line plain text logs (which are notoriously difficult to parse into structured fields like `level: ERROR` or `trace_id: 12345`).
   * **The Execution**: The backend's `logback-spring.xml` configuration was refactored to employ a Logstash encoder. This forces the application to natively output structured JSON. Because the logs are pre-structured, Filebeat requires zero complex parsing rules—it just ingests the JSON directly into Elasticsearch, meaning developers can instantly query specific key-value pairs in Kibana.
5. **ArgoCD Bootstrapping**
   * **The Execution**: The entire ELK stack was deployed via declarative GitOps manifests (`ops/k8s/logging/`) synchronized by ArgoCD.

## 📂 Project Structure
```text
.
├── .github/workflows/             # 🐙 GitHub Actions Pipelines (DevSecOps Scans)
├── .gitlab-ci.yml                 # 🦊 GitLab CI Pipeline (Legacy UI/API Deployments)
├── Jenkinsfile                    # 🕴️ Jenkins Pipeline (GitOps Image Building)
├── backend/                       # ✅ Spring Boot App 
│   └── src/main/resources/
│       └── logback-spring.xml     # 🖨️ Structured JSON logger configuration
├── frontend/                      # ✅ React App 
└── ops/
    ├── ansible/                   # ⚙️ Ansible Configuration Management
    ├── cost-exporter/             # 💸 Python FinOps Exporter
    ├── helm/                      # ☸️ The Portable Amazon-App Helm Chart
    ├── k8s/                       
    │   ├── logging/               # 🪵 Centralized Logging ArgoCD Definitions (ELK Stack)
    │   │   ├── elasticsearch-app.yaml
    │   │   ├── filebeat-app.yaml
    │   │   ├── kibana-app.yaml
    │   │   └── namespace.yaml
    │   └── argocd-app.yaml        
    └── terraform/                 # 🏗️ Terraform Infrastructure as Code
```

---
*Created as the Centralized Logging iteration for a DevOps Reference Architecture journey.*
