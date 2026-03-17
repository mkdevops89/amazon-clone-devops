# ops/terraform/environments/dev/iam/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/iam"
}

inputs = {
  environment = "dev"
  project     = "amazon-clone"
  
  # Preventing the recreation of these policies to avoid downtime
  cost_explorer_policy_name = "AmazonCloneCostExplorerPolicy"
  bedrock_policy_name       = "AmazonCloneBedrockInvokePolicy"
}
