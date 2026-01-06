# Phase 14: Advanced IaC with Terragrunt (Structure & Scaling)

**Goal**: Don't Repeat Yourself (DRY). Manage separate environments (`prod`, `stage`, `dev`) without copying Terraform files.
**Role**: Cloud Architect.

## 🛠 Prerequisites
*   **Terraform**: Installed.
*   **Terragrunt**: `brew install terragrunt`.

## 📝 Concept
*   **Terraform**: "Hardcoded" inputs. `vpc_cidr = "10.0.0.0/16"`.
*   **Terragrunt**: "Dynamic" inputs. It calls the Terraform module and injects `inputs=...` at runtime. It also auto-generates the `backend.tf` so you don't have to write it 100 times.

## 📝 Step-by-Step Runbook

### 1. View the Structure
Navigate to `ops/terragrunt`.
```
terragrunt.hcl          # ROOT (Defines S3 Bucket / DynamoDB Lock)
live/
  prod/
    vpc/
      terragrunt.hcl    # CHILD (Defines Inputs: CIDR, Name)
```

### 2. Configure Credentials
Terragrunt uses standard AWS credentials.
```bash
export AWS_PROFILE=default
```

### 3. Initialize (Prod VPC)
Go to the specific "Leaf" module.
```bash
cd ops/terragrunt/live/prod/vpc
terragrunt init
```
*   **Notice**: It asks "Do you want to create S3 bucket amazon-clone-terraform-state?".
*   **Say Yes**: It automates the backend creation!

### 4. Plan
```bash
terragrunt plan
```
*   You will see it downloading the `terraform-aws-modules/vpc/aws`.
*   It plans the creation of a VPC with `10.0.0.0/16`.

### 5. Apply
```bash
terragrunt apply
```

### 6. Create a "Dev" Environment (Exercise)
To prove the power of Terragrunt:
1.  Copy `ops/terragrunt/live/prod` to `ops/terragrunt/live/dev`.
2.  Edit `dev/vpc/terragrunt.hcl`.
3.  Change `cidr` to `10.1.0.0/16` and `Environment` to `dev`.
4.  Run `terragrunt apply` in the new folder.
5.  **Result**: 2 Identical environments, 0 duplicated code.

## 🚀 Troubleshooting
*   **"Bucket already exists"**: S3 bucket names are global. Change the bucket name in the ROOT `ops/terragrunt/terragrunt.hcl` to something unique (e.g., `amazon-clone-<yourname>`).
*   **"Lock Error"**: Check DynamoDB in AWS Console and delete the lock item if it's stuck.
