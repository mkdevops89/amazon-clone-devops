# Architecture and delivery notes

This page summarizes the configuration present on the repository's `main` branch. A configured component is not evidence that it is currently deployed or healthy.

## Application path

The frontend is a Next.js/React application. It calls a Spring Boot API. Backend configuration references MySQL, Redis, RabbitMQ through Amazon MQ, Cognito JWT validation, and Amazon Bedrock. The exact runtime dependencies and credentials must be supplied by the deployment environment.

## Infrastructure and delivery path

Terraform modules and Terragrunt environment folders describe AWS network, EKS, managed data services, IAM, ECR, DNS, S3, Cognito, budgets, and related resources. The Helm chart and Argo CD resources describe deployment to EKS. Jenkins and GitHub Actions files represent multiple stages of the project's delivery history; not every pipeline is active on the default branch or wired to the same deployment path.

The latest visible `main` run of `Amazon Clone CI/CD` failed in its backend and frontend build jobs. Downstream image-scan and DAST jobs were skipped. Check the run directly for step-level logs before diagnosing the cause.

## Historical branch policy

Branches named for earlier phases preserve iterations of the project. The current default branch is the source for this overview. A branch existing in Git does not mean its workflow, infrastructure or deployment is currently supported. In particular, workflows that trigger only on old phase branches should be treated as historical until their triggers and credentials are reviewed.

## Review boundaries

- No current AWS runtime state was queried as part of this repository review.
- Terraform plans and apply results were not run.
- Kubernetes and Helm manifests were inspected as source, not applied to a cluster.
- Workflow configurations were inspected; a failing public run was identified, but its step logs were not available through the public run summary used here.
- Security policy mappings and STIG-aligned examples are project documentation, not evidence of certification or an independent audit.

## Material security and operations risks

- The EKS API endpoint remains public but is now restricted by required `ADMIN_SOURCE_CIDR` input. Bastion SSH uses the same input; selected node service ports are limited to the VPC CIDR. Confirm the configured CIDR is a trusted administrative network before provisioning.
- Jenkins agents include privileged Docker-in-Docker and several mutable tool image tags. Pin and isolate build tooling before treating the pipeline as hardened.
- A JWT signing value was previously committed in application configuration. Source now requires `JWT_SECRET`; rotate the value in any environment where the former value was used. Git history still contains it.
- Some teardown and compliance documents include strong guarantees that are not demonstrated by the current source. Validate every destructive command, retention setting, and control mapping against the deployed account before use.
