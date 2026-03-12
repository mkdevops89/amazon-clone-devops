# 💰 FinOps & Cost Optimization Review

## 1. Executive Summary
As the platform has stabilized through Phase 15, our focus must shift to micro-optimizations. While the Hybrid Spot Node architecture reduced gross compute costs by 70%, several secondary infrastructure resources remain unoptimized.

## 2. Identified Cost Leaks

### A. CloudWatch Logs vs. ELK Stack (Double Billing)
- **Issue:** We deployed a self-hosted ELK stack for centralized logging, completely eliminating our reliance on AWS CloudWatch. However, the EKS cluster and various Lambda functions are still emitting logs to CloudWatch log groups by default.
- **Remediation:** Implement a Terraform configuration (`aws_cloudwatch_log_group`) with a draconian 1-day retention policy, or disable EKS control plane logging if compliance permits.

### B. Orphaned Elastic Block Store (EBS) Volumes
- **Issue:** During Kubernetes upgrades and StatefulSet replacements (Nexus, Jenkins, SonarQube), the underlying EBS volumes are sometimes detached but not automatically destroyed. AWS continues to charge for provisioned storage.
- **Remediation:** Write a Python Lambda function triggered weekly by EventBridge to scan for and delete any EBS volume with an `available` state (unattached) that is older than 7 days.

### C. NAT Gateway Data Transfer Costs
- **Issue:** Private EKS nodes frequently pull public Docker images from DockerHub and push large metrics. This traffic traverses the AWS NAT Gateway, accumulating massive per-GB data processing fees.
- **Remediation:** Introduce **AWS VPC Endpoints (PrivateLink)** for S3, ECR, and CloudWatch. This routes AWS-native traffic internally, bypassing the expensive NAT Gateway.

### D. Untagged AWS Resources
- **Issue:** It is difficult to attribute infrastructure spend back to specific business units because many basic EC2, VPC, and S3 resources lack standardized tags.
- **Remediation:** Enforce `default_tags` at the AWS Provider level inside `ops/terraform/aws/main.tf` to universally tag all generated resources with `Project: AmazonClone` and `Environment: Dev/Prod`.
