# ops/terraform/environments/dev/serverless/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/serverless"
}

inputs = {
  environment              = "dev"
  project                  = "amazon-clone"
  
  lambda_role_name         = "amazon-clone-dev-cost-optimizer-role"
}
