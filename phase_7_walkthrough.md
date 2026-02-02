# Phase 7: Senior Automation - Execution Guide

This guide explains how to **run and verify** the new automation tools created in Phase 7.

## 1. Setup Environment
Ensure you have the following installed:
*   Python 3.9+
*   Go 1.18+
*   Terraform 1.0+
*   AWS CLI (configured with credentials)

```bash
# Verify installations
python3 --version
go version
terraform -version
```

---

## 2. 🐍 Run "The Cost Terminator" (Local)
You can run the Python Lambda logic directly on your machine to test it (Dry Run).

### Step 1: Install Dependencies
```bash
cd ops/lambda/cost_optimizer
pip3 install -r requirements.txt
```

### Step 2: Test the Logic
Create a temporary `test_local.py` file to invoke the handler:

```bash
cat <<EOF > test_local.py
from index import lambda_handler

# Verify the function loads and prints "Stop" action
print("🚀 Simulating Nightly Stop Event...")
lambda_handler({"action": "stop"}, {})
EOF
```

Run the test:
```bash
# Ensure AWS Credentials are active
export AWS_PROFILE=default  # Change if needed

python3 test_local.py
```
*Expected Output*: Logs showing "Scale down", "Stop instances", or "cleanup".

### Step 3: Restore the System (Start)
To bring everything back up manually (simulate morning start):

**Run this Python one-liner:**
```bash
cd ops/lambda/cost_optimizer
python3 -c "from index import lambda_handler; lambda_handler({'action': 'start'}, {})"
```
*Expected Output*: "Restoring EKS Node Groups...", "Starting Dev EC2 Instances..."

```
### Step 4: Tag Your Resources (Required)
The automation **only** touches resources with the tag `Environment=Dev`. 
If your instances are running after the test, they are likely missing this tag.

**Tag them using AWS CLI:**
```bash
# Tag all instances in your VPC (Be careful!)
aws ec2 create-tags --resources i-0123456789abcdef0 --tags Key=Environment,Value=Dev
```
*Replace the instance ID with your actual instance ID.*

---

## 3. 🛡️ Run "The Auto-Healer" (Local)
Test the remediation logic.

### Step 1: Install Dependencies
```bash
# Re-use the same virtualenv or install
cd ../auto_healer
# (This shares requirements with cost_optimizer usually, or install boto3)
pip3 install boto3
```

### Step 2: Test Security Group Revocation
```bash
cat <<EOF > test_healer.py
from index import check_security_group_compliance

# Simulate a "Bad" Audit Event (Port 22 Open to World)
fake_event = {
    "requestParameters": {
        "groupId": "sg-12345fake",
        "ipPermissions": {
            "items": [{
                "fromPort": 22,
                "toPort": 22,
                "ipRanges": {"items": [{"cidrIp": "0.0.0.0/0"}]}
            }]
        }
    }
}

print("🛡️ Testing Auto-Healer Compliance Check...")
check_security_group_compliance(fake_event)
EOF
```

Run it:
```bash
python3 test_healer.py
```

---

## 4. 🐹 Run "Ops Check" (Go CLI)
Compile and run the binary tool to check your Kubernetes cluster.

### Step 1: Go to Directory
```bash
cd ../../cli/ops-check
```

### Step 2: Run directly
```bash
# This uses your local ~/.kube/config
go run main.go
```

### Step 3: Compile (Optional)
To create a binary you can share with the team:
```bash
go build -o ops-check
./ops-check
```
*Expected Output*: A list of ✅ (Ready) or ❌ (Failed) nodes and pods.

---

## 5. 🏗️ Deploy Infrastructure (Terraform)
Deploy the Lambda functions and EventBridge schedules to AWS.

### Step 1: Initialize
```bash
cd ../../terraform/aws
terraform init
```

### Step 2: Plan
See what will be created (Lambdas, Roles, Rules):
```bash
terraform plan
```

### Step 3: Apply (Selective)
To deploy *only* the new automation without touching existing infrastructure:
```bash
terraform apply -target=aws_lambda_function.cost_optimizer \
                -target=aws_lambda_function.auto_healer \
                -target=aws_cloudwatch_event_rule.nightly_stop
```

---

## 🧹 Cleanup (After Testing)
To remove the local test files:
```bash
rm ops/lambda/cost_optimizer/test_local.py
rm ops/lambda/auto_healer/test_healer.py
rm ops/cli/ops-check/ops-check
```
