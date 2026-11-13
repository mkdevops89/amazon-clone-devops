# Cost review notes

This document identifies likely cost drivers from repository configuration. It does not contain measured AWS charges, savings, or a comparison of before-and-after costs.

## Configured cost drivers to review

| Resource area | Repository evidence | Cost review question |
|---|---|---|
| EKS worker nodes | `ops/terraform/modules/eks/main.tf` configures an On-Demand `t3.xlarge` node group and a Spot node group. | What are the actual node count, utilization, interruption effects, and regional rates? |
| NAT and load balancing | VPC and Kubernetes ingress configuration define network paths that may create NAT gateway and load balancer charges. | Which gateways and load balancers exist, and what data processing or hourly costs appear in billing? |
| Managed data services | Terraform defines RDS, ElastiCache, and Amazon MQ resources. | Which resources are currently provisioned, and are snapshots or storage retained after teardown? |
| Persistent volumes and logs | Kubernetes and logging configuration can create EBS and log-storage costs. | Which volumes and log groups exist, what retention is configured, and are any resources unattached? |
| Container registries | ECR modules and image publishing configuration are present. | How many images and layers are stored, and is an actual lifecycle policy attached? |

## Measurement before optimization

Use AWS Cost Explorer or billing exports for the target account and time range. Record service-level costs, relevant resource identifiers, dates, and the deployment state. Compare equivalent periods before claiming a reduction. Do not automatically delete unattached volumes or snapshots without confirming ownership and retention requirements.

## Status

No cost-saving percentage is asserted. Cost controls and automation code in the repository are examples until their deployment and observed effects are verified in the target AWS account.
