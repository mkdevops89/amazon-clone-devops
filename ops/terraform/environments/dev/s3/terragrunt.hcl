# ops/terraform/environments/dev/s3/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

# Explicitly instruct Terragrunt to skip this directory during all parent run-all executions
# to securely protect the WORM-locked AWS Evidence vaults during teardowns!
skip = true

terraform {
  source = "../../../modules/s3"
}

inputs = {
  environment = "dev"
  project     = "amazon-clone"
}
