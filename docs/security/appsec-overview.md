# Enterprise Application Security (AppSec) Overview

## 1. Defense-in-Depth Architecture
The Amazon Clone DevSecOps architecture implements a strict "Defense-in-Depth" layered security model:

*   **Layer 3/4 (Network):** Private EKS Subnets, NAT Gateways, Security Groups restricting inter-node traffic.
*   **Layer 7 (Application):** AWS Application Load Balancer (ALB) enforcing TLS 1.3 encryption for all ingress traffic (`https://devcloudproject.com`). NGINX Ingress Controller enforcing HTTP Strict Transport Security (HSTS) and anti-clickjacking headers.
*   **Identity & Access (IAM):** Amazon Cognito providing OAuth 2.0 / JWT issuance. Spring Security Gateway enforcing granular Role-Based Access Control (RBAC) on all backend API routes.
*   **Supply Chain (Zero-Trust):** Kyverno Admission Controller aggressively denying the deployment of any proprietary container image lacking a valid mathematical `cosign` signature.
*   **Kernel Runtime (eBPF):** Sysdig Falco actively monitoring Linux system calls inside Kubernetes containers to instantly alert on rogue bash shells or unauthorized file reads (e.g., `/etc/shadow`).

---

## 2. STRIDE Threat Model Analysis

To anticipate and mitigate potential attacks targeting the Spring Boot/Next.js ecosystem, we apply the Microsoft **STRIDE** methodology.

| Threat Type | Description | Targeted Asset | Mitigation Strategy Applied |
| :--- | :--- | :--- | :--- |
| **S**poofing | Attacker impersonates an admin user. | User Accounts, API Gateway | Amazon Cognito MFA, strict JWT validation at the Spring Cloud Gateway. |
| **T**ampering | Malicious actors modify Docker images. | AWS ECR, Kubernetes | **Cosign** cryptographic signatures verified by **Kyverno** at runtime. |
| **R**epudiation | Users deny performing destructive actions. | AWS Infrastructure, K8s | Immutable centralized logging via **AWS CloudTrail** archived to WORM S3. |
| **I**nformation Disclosure | Extraction of sensitive database credentials. | PostgreSQL, Application Pods | Secrets vaulted in AWS Secrets Manager, injected dynamically via External Secrets Operator. (No hardcoded `.env` files). |
| **D**enial of Service | Botnets flooding the Next.js frontend. | ALB, EKS Nodes | AWS ALB innate protections, Karpenter Auto-scaling to absorb traffic spikes. |
| **E**levation of Privilege| Container breakout to compromise EKS worker node. | Linux Kernel, Docker Daemon | Container security contexts configured (`runAsNonRoot`), **Sysdig Falco eBPF** behavioral monitoring. |

---

## 3. Secure Software Development Life Cycle (SSDLC)

All proprietary code modifications must pass through an automated, cryptographically bound CI/CD pipeline (Jenkins). Any failure in this chain halts the deployment.

1.  **Static Application Security Testing (SAST):** SonarQube scans the Next.js and Spring Boot raw source code for OWASP Top 10 vulnerabilities (e.g., SQL Injection, Hardcoded Tokens).
2.  **Software Composition Analysis (SCA):** Jenkins generates a comprehensive Software Bill of Materials (SBOM) using `syft` and aggressively scans all operating system libraries (Alpine/Debian) and application dependencies (NPM/Maven) using `trivy`.
3.  **Cryptographic Attestation:** Upon passing all security gates, the `cosign` binary uses a vaulted private key to sign the specific SHA-256 Digest of the Docker image and pushes the signature as a `.sig` artifact to ECR.
4.  **Zero-Trust Deployment:** ArgoCD attempts to deploy the new Kubernetes deployment manifest. The Kyverno Admission Webhook intercepts the request, queries AWS ECR for the `.sig` artifact, validates the cryptography, and only then authorizes the EKS Control Plane to spin up the pod.

---

## 4. Vulnerability Remediation SLAs

When automated scans (Trivy, GuardDuty) or external audits detect vulnerabilities, the Engineering team is strictly bound by the following Service Level Agreements based on the Common Vulnerability Scoring System (CVSS v3.1).

| CVSS Severity | Score Range | Maximum Remediation Timeframe | Required Action |
| :--- | :--- | :--- | :--- |
| **CRITICAL** | 9.0 - 10.0 | **< 48 Hours** | Immediate hotfix. Production deployments halted until resolved. |
| **HIGH** | 7.0 - 8.9 | **< 7 Days** | Prioritized in current sprint. Temporary WAF rules applied if no direct patch exists. |
| **MEDIUM** | 4.0 - 6.9 | **< 30 Days** | Scheduled into the standard Agile backlog. |
| **LOW** | 0.1 - 3.9 | **< 90 Days** | Addressed during routine technical debt/maintenance cycles. |

*Note: Any deviations from these SLAs must be manually risk-accepted and signed off by the acting Security Architect or CISO.*
