# Infrastructure teardown and recovery review

> **Review document, not an executable runbook.** The steps previously described here included unverified resource-retention and recovery assumptions. Do not copy commands from older revisions of this file into an AWS account.

## Current repository evidence

- Terraform modules are invoked through Terragrunt under `ops/terraform/environments/dev/`.
- The EKS module provisions EKS and managed data services. RDS is configured with `skip_final_snapshot = true`; destroying it can delete database data without creating a final snapshot.
- Kubernetes platform and application resources are declared in both Helm and Kubernetes/Argo CD configuration. A live cluster was not inspected during this review.
- The repository does not establish that an S3 evidence bucket has Object Lock enabled, that a seven-year retention policy exists, or that retained volumes can be rebound to a replacement cluster.
- The EKS module's Terraform-generated bastion key is written to a local path and is also represented in Terraform state.

## Preconditions for a safe teardown procedure

Before writing or running a teardown procedure, an operator should:

1. Confirm the AWS account, region, Terraform/Terragrunt state backend, and exact resources managed by each stack.
2. Identify required database, object, and persistent-volume data; create and verify backups if data must be retained.
3. Review Terraform plans for each module and explicitly identify resources that will be destroyed or retained.
4. Check Argo CD reconciliation and cluster add-ons so they do not recreate resources during teardown.
5. Destroy dependency layers in the order shown by the current Terragrunt configuration, then inspect AWS for remaining billable resources.
6. Record what was verified, including state locking, snapshots, volumes, load balancers, NAT gateways, EIPs, and log storage.

## Recovery procedure status

A full rebuild sequence is not currently validated. Re-establishing infrastructure may require state-backend access, account-specific secrets, DNS and certificate setup, cluster add-ons, persistent storage, GitOps bootstrap, and application configuration. Validate each dependency in a disposable environment before describing this project as disaster-recovery tested.
