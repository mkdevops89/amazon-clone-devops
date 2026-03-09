# 📦 Amazon-Like E-Commerce Platform (Phase 15: AWS Cognito & GitOps Decoupling)

## 🚀 Phase 15 Overview
This branch (`phase-15-cognito`) focuses on transitioning the Amazon Clone application from a homegrown JWT authentication mechanism to an enterprise-grade **AWS Cognito Identity Provider**, while simultaneously hardening the DevSecOps CI/CD pipeline by introducing **Dynamic Environment Decoupling**.

## 🔐 AWS Cognito Authentication Architecture

### 1. Infrastructure (Terraform)
We provisioned a robust, serverless authentication backend:
*   **`aws_cognito_user_pool`**: The core directory storing customer emails and cryptographic user subjects (`sub`).
*   **`aws_cognito_user_pool_client`**: The OAuth App Client bridging Next.js to the Cognito directory.
*   **`aws_cognito_user_pool_domain`**: The Hosted UI Domain that powers the secure AWS backend login processing.
*   **AWS Systems Manager (SSM)**: Engineered Terraform to export the 3 dynamically generated AWS Cognito Identifiers directly into the SSM Parameter Store to completely eliminate hardcoded `.env` files.

### 2. Application Security Refactoring
#### Spring Boot Backend
*   **OAuth2 Resource Server**: Integrated `spring-boot-starter-oauth2-resource-server` so the backend naturally authenticates the AWS Cognito JWKS (JSON Web Key Set).
*   **Silent Database Synchronization**: Implemented `CurrentUserController.java`. When a user authenticates via Next.js and hits the backend, Spring automatically extracts their Cognito `sub` identifier and silently bridges them into the local MySQL `users` table so features like the Shopping Cart seamlessly persist.

#### Next.js Frontend
*   **Amplify SDK Integration**: Injected `@aws-amplify/ui-react` globally.
*   **Amazon Clone Aesthetics**: Heavily customized the default AWS Amplify `<Authenticator>` form by overriding `.amplify-tabs__list` to perfectly match the exact aesthetic and styling of the authentic Amazon.com login experience.
*   **Strict API Authentication**: Upgraded the `ProductCard` and `Cart` components to strictly use an authenticated `api.post` Axios instance, ensuring the Cognito `Authorization` Bearer token is permanently attached to all Shopping Cart transactions.

## 🏗️ Enterprise CI/CD Hardening

### 1. Infrastructure Paralysis Resolution
*   **The Problem:** The `t3.large` (2 vCPU) EKS instance was suffering constant CPU credit starvation (sustaining 295% burst capacity) while hosting Jenkins, Nexus, SonarQube, Grafana, and Elasticsearch simultaneously, causing nodes to crash.
*   **The Solution:** Executed a Terraform state modification to scale the critical workload node up to a `t3.xlarge` (4 vCPUs, 16GB RAM), successfully severing orphaned EBS `VolumeAttachment` objects to restore the cluster entirely without data loss.

### 2. Dynamic Pipeline Variable Injection
*   **The Problem:** The Next.js frontend historically required `NEXT_PUBLIC_` AWS Cognito IDs to be statically hardcoded into `.env.production` before Docker compilation, violating core Zero-Trust CI/CD automation principles.
*   **The Solution:** Rewrote the `Jenkinsfile` CI/CD pipeline to natively execute `aws ssm get-parameter` inside the pipeline runner, dynamically pulling the live AWS Identifiers and injecting them into the `docker build --build-arg` command.

### 3. Enterprise GitOps Decoupling (Phase 15.6)
*   **The Problem:** ArgoCD was forced to painfully track 16 different `phase-*` branches, requiring error-prone manual YAML revisions every time a new sprint started.
*   **The Solution:** 
    1. Spawned a permanent, immutable `gitops-dev` environment branch. 
    2. Locked ArgoCD to exclusively monitor `gitops-dev`.
    3. Programmed the `Jenkinsfile` to dynamically detect its executing branch (`env.BRANCH_NAME`), build the Docker images, and natively `git checkout gitops-dev` to merge the updated Helm configurations directly into the deployment state branch. 
    4. **Result:** Developers can branch infinitely without ever touching a pipeline script again.
