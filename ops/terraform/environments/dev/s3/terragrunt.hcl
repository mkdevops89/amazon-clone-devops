# ops/terraform/environments/dev/s3/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/s3"
}

inputs = {
  environment = "dev"
  project     = "amazon-clone"
}
