# Phase 7: Senior Automation & Custom Tools Walkthrough

## 🚀 Goal Assessed
**Transition from "Scripting" to "Platform Engineering".**
Instead of simple Bash scripts running on a server, we have built a **Serverless, Event-Driven Automation Platform** using custom Python/Go tools and Terraform.

## 🛠️ Created Tools

### 1. The Cost Terminator (Python/Lambda)
*   **Location**: `ops/lambda/cost_optimizer/`
*   **Type**: Serverless Function (AWS Lambda).
*   **Trigger**: EventBridge Cron (Nightly at 8 PM, Morning at 6 AM).
*   **Logic**:
    *   **Scale-Down**: Sets EKS Node Groups (`min`/`desired`) to **0** to stop hourly compute charges.
    *   **Stop Instances**: Stops any EC2/RDS instance tagged `Environment=Dev`.
    *   **Reaper**: Deletes `available` (unattached) EBS Volumes and unassociated EIPs to prevent "zombie" costs.

### 2. The Auto-Healer (Python/Lambda)
*   **Location**: `ops/lambda/auto_healer/`
*   **Type**: Reactive Function (AWS Lambda).
*   **Trigger**: CloudWatch Alarms (SNS) or CloudTrail Events.
*   **Logic**:
    *   **Disk Pressure**: If disk > 90%, it runs an SSM Command to `rm -rf /tmp/*` and `docker prune`.
    *   **Security Guard**: If a Security Group opens port 22 to `0.0.0.0/0`, it **instantly revokes** the rule.

### 3. Ops Check (Go CLI)
*   **Location**: `ops/cli/ops-check/`
*   **Type**: Compiled Binary (Golang).
*   **Usage**: Engineers run `ops-check` locally.
*   **Logic**: Instantly validates:
    *   Node Health (Ready/NotReady).
    *   Pod Status (Pending/CrashLoopBackOff).
    *   (Future) Quota limits and latent issues.

### 4. Drift Detective (Terraform/CodeBuild)
*   **Location**: `ops/terraform/aws/drift_detection.tf`
*   **Type**: Scheduled CI Task (AWS CodeBuild).
*   **Trigger**: Daily at Midnight.
*   **Logic**: Runs `terraform plan -detailed-exitcode`. If it returns exit code `2` (changes detected), it alerts the team, catching "ClickOps" changes.

## 🏗️ Infrastructure Architecture
All automation infrastructure is defined as code in `ops/terraform/aws/lambda.tf`:
*   **IAM Roles**: Least-privilege roles for Lambdas to manage EC2/EKS.
*   **EventBridge Rules**: Cron schedules for triggers.
*   **Lambda Functions**: Python runtime configurations.

## ✅ Verification Steps

### 1. Build the CLI Tool
```bash
cd ops/cli/ops-check
go build -o ops-check
./ops-check
```

### 2. Deploy Infrastructure
```bash
cd ops/terraform/aws
terraform init
terraform apply -target=aws_lambda_function.cost_optimizer -target=aws_lambda_function.auto_healer
```

### 3. Test Lambda Logic (Dry Run)
Invoke the function via AWS CLI with a test payload:
```bash
aws lambda invoke --function-name cost_terminator --payload '{"action": "stop"}' response.json
cat response.json
```
