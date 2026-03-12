# 🗑️ Resource Decommissioning Plan

## 1. Objective
To reduce AWS costs and minimize security vulnerabilities, we must forcefully decommission unused cloud resources and stale code identified in the Technical Debt Register.

## 2. Target 1: Unused ECR Images
Our Jenkins CI pipeline tags a new Docker image for every single Git commit. Over time, Amazon Elastic Container Registry (ECR) fills up with thousands of obsolete gigabytes.
- **Plan:** Apply an automated ECR Lifecycle Policy (`ops/scripts/cleanup/ecr-retention-policy.json`) to automatically expire untagged images or images older than 14 days.

## 3. Target 2: Orphaned Terraform State Files
During the transition from local `backend.tf` execution to CI/CD automation, several local state files (`terraform.tfstate`) may have been accidentally committed.
- **Plan:** Execute `git filter-repo` or simple `git rm --cached` interventions to scrub any `.tfstate` files from the repository's history to prevent credential leakage.

## 4. Target 3: Extraneous Kubernetes Namespaces
Check the EKS cluster for namespaces that were used for temporary sandboxes but were never deleted.
- **Plan:** Admin executes `kubectl get namespaces` and then `kubectl delete namespace <sandbox>` to rapidly free up CPU and Memory reserved by dormant pods inside the cluster.
