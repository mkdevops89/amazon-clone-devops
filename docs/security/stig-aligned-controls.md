# DISA STIG Aligned Baseline Controls

This document serves as an ongoing matrix mapping our DevSecOps architecture to standard Federal cybersecurity requirements (inspired by DISA STIGs and CIS Benchmarks).

## 1. Kubernetes & Container Hardening
*   **Control:** V-242414 | "The Kubernetes cluster must restrict execution of privileged containers."
*   **Implementation:** Kyverno `ClusterPolicy` rules (`disallow-root-user.yaml`) strictly block pods attempting to elevate to root.
*   **Control:** V-242415 | "The Kubernetes cluster must ensure containers run with a read-only root filesystem."
*   **Implementation:** Enforced natively via the Kyverno `require-ro-rootfs` policy mapping.

## 2. CI/CD Pipeline & Code Integrity
*   **Control:** V-222220 | "The CI/CD pipeline must cryptographically sign deployment artifacts."
*   **Implementation:** Sigstore Cosign is natively integrated into the Jenkinsfile, signing all Docker images prior to ECR upstream pushes.
*   **Control:** V-222221 | "Vulnerabilities must be detected prior to deployment."
*   **Implementation:** Trivy Config and SonarQube are configured as hard gates in the Jenkins CI pipeline. Artifacts failing SLA thresholds invoke `exit 1` stops.

## 3. Host & OS Security (Ansible)
*   **Control:** V-230222 | "The operating system must not permit direct root logins."
*   **Implementation:** Managed automatically via `ops/ansible/playbooks/stig-baseline.yaml`, modifying `/etc/ssh/sshd_config` to `PermitRootLogin no`.
*   **Control:** V-230223 | "The operating system must configure auditd to log all permission modifications."
*   **Implementation:** Baseline Ansible playbooks deploy custom `/etc/audit/rules.d/stig.rules` covering all IAM files.

## 4. Audit & Accountability (Evidence Retention)
*   **Control:** V-230224 | "The system must retain audit and vulnerability records immutably."
*   **Implementation:** The Jenkins pipeline securely uses `aws s3 cp` to automatically flush all generated Trivy, SBOM, and ZAP reports to an isolated AWS S3 bucket configured with WORM (Write Once, Read Many) Object Lock retention policies.
