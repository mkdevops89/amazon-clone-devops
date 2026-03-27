# ops/terraform/environments/dev/eks/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/eks"
}

# Explicitly establish an infrastructure dependency sequence.
# 1. We mathematically CANNOT build the EKS Cluster without the newly deployed VPC Networking IDs.
dependency "networking" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id         = "mock-vpc-id"
    private_subnets = ["mock-subnet-1", "mock-subnet-2"]
    public_subnets  = ["mock-subnet-11", "mock-subnet-12"]
    vpc_cidr_block = "10.0.0.0/16"
  }
}

# 2. The Worker Nodes also require the IAM Policies to be provisioned first.
dependency "identity" {
  config_path = "../iam"
  
  mock_outputs = {
    cost_explorer_policy_arn  = "arn:aws:iam::123456789012:policy/mock-cost-explorer"
    bedrock_invoke_policy_arn = "arn:aws:iam::123456789012:policy/mock-bedrock-invoke"
    reports_upload_policy_arn = "arn:aws:iam::123456789012:policy/mock-reports-upload" # Note: S3 module handles this
  }
}

inputs = {
  environment              = "dev"
  project                  = "amazon-clone"
  
  # Inject the downstream Networking variables
  vpc_id                   = dependency.networking.outputs.vpc_id
  private_subnets          = dependency.networking.outputs.private_subnets
  public_subnets           = dependency.networking.outputs.public_subnets
  vpc_cidr_block           = dependency.networking.outputs.vpc_cidr_block
  
  # Inject the downstream IAM Identity variables
  cost_explorer_policy_arn  = dependency.identity.outputs.cost_explorer_policy_arn
  bedrock_invoke_policy_arn = dependency.identity.outputs.bedrock_invoke_policy_arn
  reports_upload_policy_arn = "arn:aws:iam::406312601212:policy/AmazonCloneReportsUploadPolicy" # Hardcoded for safety during state move
  
  # Smart Overrides: Freeze these specific names to prevent the EKS Cluster and databases
  # from being destroyed & recreated due to the new multi-tenant naming convention.
  cluster_name            = "amazon-cluster"
  db_name                 = "amazon-db"
  
  # Inject the Dynamic Disaster Recovery parameter directly from the Terminal Environment!
  snapshot_identifier     = get_env("RESTORE_SNAPSHOT_ID", null)

  redis_cluster_id        = "amazon-redis"
  
  db_sg_name              = "amazon-db-sg"
  redis_sg_name           = "amazon-redis-sg"
  mq_sg_name              = "amazon-mq-sg"
  db_subnet_group_name    = "amazon-db-${dependency.networking.outputs.vpc_id}-subnet-group"
  redis_subnet_group_name = "amazon-redis-${dependency.networking.outputs.vpc_id}-subnet-group"
}
