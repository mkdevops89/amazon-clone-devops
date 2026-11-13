# Decommissioning review backlog

This file lists checks to complete before proposing resource deletion. It is not authorization to delete cloud resources, and no live AWS inventory was available during this review.

## Review items

1. **ECR retention:** inspect the lifecycle policy and repositories in AWS. The existence of `ops/scripts/cleanup/ecr-retention-policy.json` alone does not establish that a policy is attached.
2. **Terraform state:** the current tracked-file scan found no Terraform state file in the default branch. Review all history and state backends separately before drawing conclusions about secret exposure.
3. **Kubernetes resources:** query the intended cluster and check ownership, PVCs, and Argo CD applications before removing namespaces or storage.
4. **Messaging services:** the backend configuration references RabbitMQ and the Terraform module provisions Amazon MQ. Do not remove it based on the presence of Kafka/Redpanda files; verify application usage and deployment state first.
5. **DNS and network resources:** inspect Route 53, load balancers, NAT gateways, EIPs, and certificates in the correct account before cleanup.

## Evidence to retain

For each proposed removal, record the resource ID, owning Terraform stack or Kubernetes controller, data-retention decision, reviewed plan or console evidence, and post-change billing check. Do not use automated deletion for volumes, snapshots, or repositories until retention and recovery requirements are confirmed.
