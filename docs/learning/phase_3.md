# Phase 3: Cloud Provisioning (Terraform)

**Goal**: Spin up "Real" Infrastructure (EKS, RDS, VPC) on AWS using code.
**Role**: Cloud Architect.

## 🛠 Prerequisites
*   **AWS CLI**: `aws configure` (Access Key / Secret Key).
*   **Terraform**: `brew install terraform`.

## 📝 Step-by-Step Runbook

### 1. Terraform Init
Terraform needs to download the plugins (AWS Provider) for your architecture.
```bash
cd ops/terraform/aws
terraform init
# Expected: "Terraform has been successfully initialized!"
```

### 2. Terraform Plan (Dry Run)
Before you spend money, see what will happen.
```bash
terraform plan -out=tfplan
```
*   **Look for green `+` signs**: These are resources to be created.
*   **Look for red `-` signs**: Resources to be deleted.
*   **Summary**: "Plan: 24 to add, 0 to change, 0 to destroy."

### 3. Terraform Apply (The "Cost" Button)
This actually creates the resources.
**WARNING**: This creates an EKS cluster (~$0.10/hour) and NAT Gateways.
```bash
terraform apply "tfplan"
```
*This will take ~15-20 minutes. Go get coffee.* ☕

### 4. Verify AWS Resources
Don't trust Terraform blindly. Check the AWS Console:
*   **VPC**: Search for "amazon-clone-vpc".
*   **EKS**: Search for "amazon-clone-cluster".
*   **RDS**: Search for "amazon-clone-db".

### 5. Connect to the Cluster
Terraform created the cluster, but your laptop doesn't know about it yet.
```bash
aws eks update-kubeconfig --region us-east-1 --name amazon-clone-cluster
# Verify
kubectl get nodes
# Expected: 2 worker nodes (ip-10-0-x-x.ec2.internal)
```

### 6. Terraform Destroy (Save Money)
**CRITICAL**: Do not leave this running if you are just learning.
```bash
terraform destroy --auto-approve
```

## 🚀 Troubleshooting
*   **"Error: specific subnet/AZ not supported"**: AWS EKS is not available in all Availability Zones (e.g., `us-east-1e`). Edit `variables.tf` to use `us-east-1a` and `us-east-1b`.
*   **"Error acquring state lock"**: Another person (or hanging process) is running terraform. Force unlock or wait.

## 🚀 Next Level
Vanilla Terraform is messy. Copying this folder for "Dev/Prod" creates code duplication.
Go to **[Phase 14: Advanced IaC with Terragrunt](./phase_14.md)** to see how to solve this.
