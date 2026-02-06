# Phase 8: Advanced FinOps - Execution Guide

This guide explains how to **deploy and verify** the Hybrid Architecture (Spot Instances) and Cost Controls.

## 1. 🏗️ Deploy Infrastructure (Terraform)
We are splitting the EKS Cluster into **Critical** (On-Demand) and **Spot** (Cheap) nodes, and adding a **Budget**.

### Step 1: Push Changes
Ensure `main.tf` and `budgets.tf` are pushed to your branch.
```bash
git add ops/terraform/aws/budgets.tf
git commit -m "feat(finops): add aws budget alert for $50"
git push
```

### Step 2: Plan
Verify the plan shows:
*   `+/-` modification to `eks_managed_node_groups` (Splitting default -> critical + spot).
*   `+` creation of `aws_budgets_budget`.
```bash
cd ops/terraform/aws
terraform plan
```
> [!WARNING]
> This change will **Replace** your existing Node Group. Terraform might say "Force Replacement".
> **This is expected**, but it causes ~10 minutes of downtime for the nodes while they swap.
> Since your Apps (Jenkins/Nexus) are stateful, they will restart on the new nodes.

### Step 3: Apply
```bash
terraform apply -auto-approve
```

---

## 2. 💸 Verify Spot Instances
Once the apply finishes (10-15 mins), verify you have **Mixed Nodes**.

### Step 1: Check Nodes
```bash
kubectl get nodes --show-labels
```
Look for the `lifecycle` label:
*   `lifecycle=OnDemand`: This is your **Critical** node.
*   `lifecycle=Ec2Spot`: These are your **Spot** nodes.

### Step 2: Verify Architecture
```bash
# Count nodes by type
kubectl get nodes -L capacity_type,failure-domain.beta.kubernetes.io/zone
```

---

## 3. 🛡️ Verify Budget
Ensure the safety net is active.

### Check via CLI (Optional)
```bash
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)
```
*Expected Output*: A JSON showing `limit_amount: 50.0`.

---

---

## 4. 🧠 Intelligent Scheduling
Now that we have a **Critical Node** (On-Demand) and **Spot Nodes**, we must tell our Stateful Apps (Jenkins, Nexus, SonarQube) to live on the Safe Node.

### Step 1: Push Manifest Changes
We updated the `jenkins.yaml`, `nexus.yaml`, and `sonarqube.yaml` to include `nodeSelector: intent=critical`.
```bash
git add ops/k8s/jenkins/jenkins.yaml ops/k8s/nexus/nexus.yaml ops/k8s/sonarqube/sonarqube.yaml
git commit -m "feat(k8s): pin stateful apps to critical node group"
git push
```

### Step 2: Apply Changes
Redeploy the applications to enforce the new rules.
```bash
kubectl apply -f ops/k8s/jenkins/jenkins.yaml
kubectl apply -f ops/k8s/nexus/nexus.yaml
kubectl apply -f ops/k8s/sonarqube/sonarqube.yaml
```

### Step 3: Verify Scheduling
Check where the pods are running. They should all be on the **Critical Node** (On-Demand).
```bash
# Get the Critical Node Name
kubectl get nodes -l intent=critical

# Check Pod Locations
kubectl get pods -n devsecops -o wide
```
*Look at the `NODE` column. It should match the Critical Node name.*

---

## 5. 📉 Optimizations (Monitoring & Right-Sizing)
We have also implemented **Enhanced Monitoring** (Node Pressure) and **Right-Sizing AI** (Cost Recommendations).

### Step 1: Push Operations Code
You need to save the Go and Python changes to your branch.
```bash
# Push Ops Check (Go)
git add ops/cli/ops-check/main.go
git commit -m "feat(ops): add memory and disk pressure checks"

# Push Cost Optimizer (Python)
git add ops/lambda/cost_optimizer/index.py
git commit -m "feat(finops): add right-sizing recommendation logic"

git push
```

### Step 2: What happens next??
1.  **Ops Check**: Run `go run main.go` locally to check your cluster health:
    ```bash
    cd ops/cli/ops-check
    go run main.go
    ```
2.  **Cost Terminator**: The Python code will be deployed next time you run Terraform (or via CI/CD pipelines). It will start analyzing your CPU usage nightly and suggest downgrades if you are over-provisioned.

---

## 6. ✅ Phase 8 Complete
You have successfully:
1.  Implemented Hybrid Architecture (Spot + On-Demand).
2.  Set up Cost Protection (Budgets).
3.  Optimized Workload Placement (Intelligent Scheduling).
4.  Adding Intelligence (Node Pressure & Right-Sizing).


