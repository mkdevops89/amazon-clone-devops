# Amazon Clone DevOps

An independent DevOps project that uses a sample e-commerce application to explore AWS infrastructure, CI/CD, container deployment, and operational controls. The repository tracks successive lab phases; it is not affiliated with Amazon and is not a production service.

## What the project demonstrates

| Area | Implementation explored |
| --- | --- |
| AWS infrastructure | EC2, networking, Terraform, Terragrunt, and Amazon EKS |
| Application delivery | Docker builds and CI examples using GitHub Actions, Jenkins, and GitLab CI |
| Kubernetes and GitOps | Helm and Argo CD deployment patterns |
| Operations | Cloud monitoring, observability with Prometheus/Grafana and ELK, and AWS cost controls |
| Security | Pipeline scanning, Kubernetes policy examples, and Linux hardening |

## Where to start

- [Jenkinsfile](Jenkinsfile) — pipeline configuration and an example of adding security checks to delivery.
- [Ansible hardening playbook](ops/ansible/playbooks/stig-baseline.yaml) — selected Linux host hardening settings.

## Phase 20: Security control demonstrations

Phase 20 adds examples of Kyverno admission policies, infrastructure configuration scanning with Trivy, and Ansible host hardening. These examples are informed by selected DISA STIG and NIST practices. They are **not** evidence of a formal assessment, certification, or production-wide enforcement. Treat configuration in the repository as a lab implementation unless a corresponding validation result is available.

Disaster recovery is a planned follow-on phase.

Companion project: [baba-app](https://github.com/mkdevops89/baba-app), an in-progress AWS security and operations project.
