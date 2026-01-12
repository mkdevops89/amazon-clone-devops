# Phase 4.5: Domain & HTTPS Configuration (Infrastructure)

**Goal:** Configure AWS Route53 (DNS) and ACM (SSL Certificate) using Terraform.
**Branch:** `phase-4.5-domain`

## 🛠 Prerequisites
*   Phase 4 deployed (EKS Cluster running).
*   A registered domain name (e.g., `devcloudproject.com`).

## 📝 Step-by-Step Runbook

### 1. Sync Code (On Execution Machine)
Switch to the new branch where the Terraform configuration lives.
```bash
git fetch
git checkout phase-4.5-domain
git pull origin phase-4.5-domain
```

### 2. Verify Configuration
Check that your domain is correctly set in `terraform.tfvars`.
```bash
cat ops/terraform/aws/terraform.tfvars
# Expected: domain_name = "devcloudproject.com"
```

### 3. Apply Terraform
Provision the Hosted Zone and request the SSL Certificate.
```bash
cd ops/terraform/aws
terraform init
terraform apply
```
*   **Review Plan:** It should show **2 to add** (Certificate + Validation Record).
*   **Confirm:** Type `yes`.

### 4. 🚨 CRITICAL: Update Registrar Name Servers
After Terraform completes, it will output `nameservers`:
```text
nameservers = [
  "ns-123.awsdns-40.com",
  "ns-456.awsdns-50.org",
  ...
]
```
1.  Log in to your Domain Registrar (GoDaddy, Namecheap, etc.).
2.  Find **"Custom DNS"** or **"Manage Name Servers"**.
3.  **Replace** the default values with the 4 servers provided by AWS.
4.  Save.

### 5. Validation
It may take 10-30 minutes for the SSL certificate to be issued after you update the name servers.
See `phase_4_5_testcases.md` for verification steps.

---

## ⏭️ Next Steps (Part 2)
Once the Certificate is **Issued**, we will get its **ARN** and update the Kubernetes Manifests (`frontend.yaml`, `backend.yaml`) to enable HTTPS.
