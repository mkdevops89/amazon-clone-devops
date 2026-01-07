# ✅ Phase 3 Verification: Infrastructure Tests

Use this document to strict validate the Terraform Provisioning in AWS.

---

## 🟢 Phase 3: Infrastructure Verification
**Scope:** Validating that AWS Resources exist and are configured correctly.

### 🧪 1. Network (VPC & Subnets)
**Command:** `aws ec2 describe-vpcs --filters Name=tag:Name,Values=amazon-vpc`
**Expected Output:**
*   State: `available`
*   CidrBlock: `10.0.0.0/16`

**Command:** `aws ec2 describe-subnets --filters Name=vpc-id,Values=<VPC_ID>`
**Expected Output:**
*   Should list **Public** and **Private** subnets across multiple AZs.

**Command:** `aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<VPC_ID>`
**Expected Output:**
*   State: `available` (Ensures private subnets can reach the internet).

**Command:** `aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=<VPC_ID>`
**Expected Output:**
*   Attachments: Should show the VPC ID (Ensures public subnets are reachable).

### 🧪 2. EKS Cluster
**Command:** `aws eks describe-cluster --name amazon-eks-cluster`
**Expected Output:**
*   Status: `ACTIVE`
*   Endpoint: `https://...` (Valid URL)
*   ResourcesVpcConfig -> PublicAccess: `true`

### 🧪 3. Database (RDS MySQL)
**Command:** `aws rds describe-db-instances --db-instance-identifier amazon-rds`
**Expected Output:**
*   DBInstanceStatus: `available`
*   Engine: `mysql`
*   PubliclyAccessible: `false` (Should be private for security)

### 🧪 4. Cache (ElastiCache Redis)
**Command:** `aws elasticache describe-replication-groups --replication-group-id amazon-redis`
**Expected Output:**
*   Status: `available`
*   ClusterEnabled: `false` (Unless using clustered mode)

---
## 🛑 Troubleshooting
*   **Init Failed?** Delete `.terraform` folder and run `terraform init` again.
*   **Plan Failed?** Check your AWS Credentials (`aws sts get-caller-identity`).
*   **Apply Timeout?** EKS takes up to 20 minutes. Be patient.
