================================================================================
MASTER RUNBOOK: PHASE 3 (TERRAFORM & INFRASTRUCTURE)
================================================================================
Author: DevOps Architecture Team
Date: 2026-01-07
Goal: Provision Production-Grade AWS Infrastructure using IaC (Infrastructure as Code).

--------------------------------------------------------------------------------
PREREQUISITES
--------------------------------------------------------------------------------
1. INSTALL TERRAFORM: https://developer.hashicorp.com/terraform/install
   - Verify: `terraform -v`
2. INSTALL AWS CLI: https://aws.amazon.com/cli/
   - Verify: `aws --version`
3. CONFIGURE AWS CREDENTIALS:
   `aws configure`
   - Access Key ID: [Your Key]
   - Secret Access Key: [Your Secret]
   - Default Region: us-east-1
   - Output format: json

--------------------------------------------------------------------------------
STEP 1: INITIALIZATION
--------------------------------------------------------------------------------
Navigate to the Terraform directory:
`cd ops/terraform/aws`

1. Initialize Terraform:
   `terraform init`
   # This downloads the AWS provider plugins.

2. Validate Configuration:
   `terraform validate`
   # Checks for syntax errors.

--------------------------------------------------------------------------------
STEP 2: PLAN (DRY RUN)
--------------------------------------------------------------------------------
See what will be created without billing you yet.

`terraform plan`
# Review the output! It should show "+ create" for:
# - VPC, Subnets, Internet Gateway
# - EKS Cluster (Control Plane)
# - RDS Instance (MySQL)
# - ElastiCache (Redis)

--------------------------------------------------------------------------------
STEP 3: APPLY (PROVISIONING)
--------------------------------------------------------------------------------
⚠️  WARNING: THIS WILL COST MONEY (Approx $0.10 - $0.20 per hour for EKS)

`terraform apply`
- Type `yes` when prompted.
- **Wait Time:** ~15-20 minutes (EKS and RDS take time to provision).

--------------------------------------------------------------------------------
STEP 5: TEARDOWN (COST SAVING)
--------------------------------------------------------------------------------
⚠️  CRITICAL: DO NOT LEAVE RUNNING OVERNIGHT unless you want a bill.

`terraform destroy`
- Type `yes` to confirm.
- Verify all resources are deleted in AWS Console.
