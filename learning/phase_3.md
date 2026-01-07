# Phase 3: Infrastructure as Code (Terraform)

**Goal:** Automate the provisioning of the production-grade AWS environment using Terraform.

In Phase 1 & 2, we manually set up resources or used Docker on a single EC2 instance. In Phase 3, we treat our infrastructure as code, allowing us to provision a scalable architecture (VPC, EKS, RDS, Redis, MQ) with a single command.

---

## 🏗️ Architecture to be Built
Running `terraform apply` will create:
1.  **VPC (Network):** A complete virtual network with Public/Private subnets and NAT Gateway.
2.  **EKS (Compute):** A Managed Kubernetes Cluster (Control Plane + Worker Nodes) for running our app containers.
3.  **RDS (Database):** A managed MySQL database (High Availability).
4.  **ElastiCache (Redis):** A managed Redis cluster for session caching.
5.  **Amazon MQ (RabbitMQ):** A managed message broker for order processing.
6.  **S3 (State):** Remote storage for Terraform state files (created via script).

---

## 🚀 Step-by-Step Implementation

### 1. Prerequisites
Ensure you have the following tools installed:
- `aws` CLI (configured with valid credentials)
- `terraform` (v1.5+)

### 2. Bootstrap Remote State (One-time Setup)
Terraform needs to store the "State" of your infrastructure safely. We use S3 for storage and DynamoDB for locking (to prevent concurrent edits).
We created a script to handle this automatically:

```bash
chmod +x ops/scripts/setup_tf_state.sh
./ops/scripts/setup_tf_state.sh
```
*Successfully running this will update your `ops/terraform/aws/versions.tf` with the correct bucket name.*

### 3. Initialize Terraform
Download the AWS providers and configure the backend:

```bash
cd ops/terraform/aws
terraform init
```

### 4. Review the Plan
See exactly what will be created before spending money:

```bash
terraform plan
```
*(Expect 40-50 resources to be added)*

### 5. Apply (Provisioning)
**WARNING:** This step incurs costs (NAT Gateway, EKS Cluster, etc.). ensure you have budget (~$0.10 - $0.20 per hour).

```bash
terraform apply
# Type 'yes' to confirm
```
*Provisioning EKS and RDS can take 15-20 minutes.*

---

## ✅ Verification
Once `apply` sends a success message, verify the outputs:

```bash
terraform output
```

You should see:
- `vpc_id`
- `eks_cluster_endpoint`
- `db_instance_endpoint` (MySQL)
- `redis_endpoint`
- `mq_broker_console_url`

You can also check the **AWS Console**:
1.  **VPC:** Look for `amazon-vpc`.
2.  **EKS:** Look for `amazon-cluster`.
3.  **RDS:** Look for `amazon-db`.

---

## 🧹 Cleanup (Destroy)
To stop paying for resources, destroy the infrastructure:

```bash
terraform destroy
```
