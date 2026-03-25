# CI/CD Pipeline Security Gates

## 1. Overview
The automated DevSecOps Jenkins pipeline enforces cryptographic security gates that algorithmically halt deployment operations if federal thresholds are breached.

## 2. Implemented Gates
| Stage | Tool | Enforcement Action |
|-------|------|--------------------|
| **Secrets Scan** | TruffleHog | Native `exit 1` block on any verified leaked key or IAM credential. |
| **SCA & SAST** | SonarQube | Blocks upstream merges if Code Smells or Vulnerability ratings fail the Quality Gate. |
| **Container Scan**| Trivy | Blocks deployment if the generated Kubernetes pod container exhibits CRITICAL CVEs. |
| **STIG Compliance**| Trivy Config| Physically parses Kubernetes YAML. Fails the build if `runAsNonRoot: false` or mutable tags are utilized. |
| **Integrity Sign** | Sigstore Cosign| Cryptographically signs all Docker images using offline KMS keys before pushing to ECR. |
