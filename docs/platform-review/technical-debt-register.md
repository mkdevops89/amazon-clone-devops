# 📉 Enterprise Technical Debt Register

## 1. Overview
As the Amazon Clone platform evolved from raw EC2 instances to a fully managed Kubernetes GitOps environment, several legacy artifacts were left behind. This register documents known technical debt that must be audited and cleaned up to optimize repository health and avoid developer confusion.

## 2. Phase 0-3: Deprecated Click-Ops & EC2 Scripts
The following scripts in `ops/scripts/` were originally used to manually provision the data layer and manage EC2 instances. They are now entirely obsolete due to our transition to Terraform and Helm charts.
- `ops/scripts/phase_0/install_mysql.sh`
- `ops/scripts/phase_0/install_redis.sh`
- `ops/scripts/phase_0/install_rabbitmq.sh`
- `ops/scripts/setup_ec2.sh`
- `ops/scripts/deploy_k8s.sh` (Replaced by GitOps)
- `ops/scripts/update_ingress_cert.sh` (Replaced by cert-manager)
**Action Required:** Move to an `ops/archive/` folder or permanently delete via a decommissioning PR.

## 3. Phase 4-7: Kubernetes Manifest Duplication & Helm Transition
Early Kubernetes adoptions relied on static manifests in `ops/k8s/`. These have since been wholly replaced by ArgoCD and the dynamic `ops/helm/amazon-app` charts.
- `ops/k8s/frontend.yaml`
- `ops/k8s/backend-deployment.yaml`
- `ops/k8s/backend-service.yaml`
- `ops/k8s/ingress.yaml`
**Action Required:** Audit the `ops/k8s/` directory and purge all manifests that overlap with the `amazon-app` Helm chart to prevent split-brain state issues.

## 4. Phase 9-10: HashiCorp Vault Deprecation
We initially deployed HashiCorp Vault for secrets management. However, in Phase 15, we fully transitioned to AWS Systems Manager (SSM) Parameter Store and the External Secrets Operator. Vault is now dead weight on the cluster.
- `ops/helm/vault-values.yaml` (Decommissioned)
**Action Required:** Ensure the Vault Helm release is completely uninstalled from the cluster, and delete the legacy `vault-values.yaml` configurations from the repository.

## 5. Phase 15: Legacy Authentication Endpoints
The Spring Boot backend still houses dead code (`LoginRequest.java`, `SignupRequest.java`, `JwtUtils.java`) originally used for homegrown JWT authentication. AWS Cognito now handles this entirely at the edge.
**Action Required:** Schedule a Java refactoring sprint to strip out these defunct payload classes and `UsernamePasswordAuthenticationFilter` logic to reduce the container attack surface.

## 6. Phase 11 & 13: Observability, Logging, & FinOps Overlap
As we matured from basic metrics to full ELK Stack logging and Prometheus monitoring, we created overlaps that generate unnecessary AWS costs.
- **Redundant Log Storage:** EKS is currently shipping default container logs to AWS CloudWatch Logs, while Filebeat is simultaneously shipping the exact same logs to our self-hosted Elasticsearch cluster. This double-billing must be severed by disabling the CloudWatch log streams.
- **Manual Grafana Dashboards:** Early Grafana dashboards were built manually in the UI (Click-Ops). They must be exported as JSON models and committed to `ops/k8s/monitoring/dashboards/` to enforce GitOps state.
- **Orphaned EBS Volumes:** Legacy StatefulSets (e.g., old versions of Nexus or SonarQube) that were deleted may have left behind unattached `gp3` Elastic Block Store volumes that are still billing monthly.
**Action Required:** Execute an AWS Cost Explorer audit for unattached EBS volumes and configure EKS to exclusively rely on ELK for application logs.

## 7. Phase 11: CI/CD Pipeline Fragmentation 
During our early automated deployments, we extensively prototyped CI/CD workflows using both **GitHub Actions** (Phase 6a) and **GitLab CI** (Phase 6c) before definitively standardizing on **Jenkins** as the Enterprise DevSecOps Hub. This led to severe CI/CD fragmentation.
- `.github/workflows/`
- `.gitlab-ci.yml`
**Action Required:** Delete all non-Jenkins pipeline definitions from the repository to establish a single source of truth for CI/CD and prevent "ghost builds" from triggering externally on GitHub or GitLab runners.

## 8. Phase 5: Route 53 DNS Sprawl & Manual Records
In the foundational phases—before fully adopting declarative Terraform `route53.tf` modules and automated Kubernetes Ingress generation—we successfully routed traffic to our early EC2 instances and ALBs via Click-Ops manual AWS Route 53 insertions.
**Action Required:** Conduct an AWS Route 53 Public Hosted Zone audit. Identify and purge any "dangling DNS" records (A/CNAME records) pointing to non-existent resources to eliminate the risk of subdomain takeover vulnerabilities. Ensure 100% of platform routing is now codified via Infrastructure-as-Code.
