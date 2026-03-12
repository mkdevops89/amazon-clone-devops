# Phase 17: Ultimate Cloud-Native Cybersecurity Architecture

## Overview
Phase 17 transforms the application into an enterprise-grade, SOC2/PCI-compliant DevSecOps platform. It introduces a four-pillar zero-trust security model that actively defends the AWS infrastructure, enforces cryptographic integrity in the CI/CD pipeline, and monitors the Linux kernel for live intrusions.

## Four Pillars of Security
1. **AWS Native Security (The Ephemeral SOC):** Automated deployment of AWS Security Hub, Amazon GuardDuty (machine learning threat detection), and persistent CloudTrail API logging.
2. **The Immutable Evidence Room:** Hardened AWS S3 bucket with strict Object Lock (Write Once, Read Many - WORM) to physically prevent the deletion or tampering of security audit logs for 7 years.
3. **Supply Chain Cryptography (Cosign & Kyverno):** Total CI/CD Pipeline overhaul to auto-generate JSON Software Bill of Materials (SBOMs), mathematically sign Docker images with `cosign`, and enforce Zero-Trust via a Mutating Admission Controller (`Kyverno`) that violently rejects unsigned pods.
4. **eBPF Kernel Monitoring (Sysdig Falco):** Runtime threat detection using modern eBPF probes to intercept malicious Linux system calls (e.g., spawning unauthorized bash shells or reading password files).

## Key Files & Directories
- `ops/terraform/aws/security.tf`: Toggleable infrastructure code for GuardDuty/Security Hub.
- `ops/terraform/aws/s3_evidence.tf`: S3 configuration enforcing WORM compliance.
- `Jenkinsfile`: Deeply modified pipeline injecting `syft`, `cosign`, and S3 archival stages.
- `ops/k8s/kyverno/policy.yaml`: Strict Kubernetes `ClusterPolicy` validating cryptographic signatures.
- `ops/helm/falco/values.yaml`: Custom runtime alert rules detecting post-exploitation activity.
- `phase_17_walkthrough.md`: Comprehensive guide featuring the "Simulated Hacks" used to test these enterprise defenses.
