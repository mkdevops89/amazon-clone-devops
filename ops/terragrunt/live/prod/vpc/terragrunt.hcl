# Include the root configuration (S3 Backend, Provider)
include "root" {
  path = find_in_parent_folders()
}

# The "Source" is the module we want to deploy.
# We use the OFFICIAL AWS VPC Module from Terraform Registry.
terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.0.0"
}

# Inputs = The variables for this specific environment (Prod)
inputs = {
  name = "amazon-clone-prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "prod"
    Project     = "AmazonLikeApp"
  }
}
