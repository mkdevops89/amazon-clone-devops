# Security configuration notes

This file records security-related configuration examples in the repository. It is not a DISA STIG implementation statement, compliance assessment, or certification. The control identifiers and mandatory language from earlier versions have been removed because they had not been verified against an authoritative baseline.

| Area | Repository evidence | What this does not establish |
|---|---|---|
| Kubernetes admission | Kyverno policy examples are under `ops/security/kyverno-policies/` and `ops/k8s/kyverno/`. | Policies are not proven installed, selected by the active cluster, or enforced on every workload. |
| Image and source scanning | GitHub Actions workflows and a Jenkins pipeline contain scanner steps. | A passing result is not established. Some steps are warning-only, triggers are branch-specific, and the latest visible main CI run failed. |
| Host configuration | Ansible playbooks include SSH and host-hardening tasks under `ops/ansible/`. | No host inventory or successful Ansible execution was reviewed. |
| Secrets delivery | External Secrets resources and Kubernetes secret references are present. | The remote secret store, IAM permissions, and runtime values were not inspected. |
| Evidence storage | S3 modules and report-upload logic are present in the repository. | Object Lock mode, retention duration, immutable storage, and successful uploads were not verified. |
| Network access | Terraform defines VPC, EKS, and security-group resources. | The live AWS security posture is unknown. The cleanup branch narrows EKS API and bastion ingress to an explicit CIDR. |

## Review guidance

For each control you want to claim, link the exact source configuration and attach a dated validation result from the intended environment. Use the applicable current DISA or organizational baseline to verify control identifiers and implementation expectations. Do not represent a configuration mapping as certification.
