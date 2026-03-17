# ops/terraform/environments/dev/cognito/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/cognito"
}

inputs = {
  environment = "dev"
  project     = "devcloudproject"
  domain_name = "auth-devcloudproject"

  callback_urls = [
    "https://www.devcloudproject.com/auth/callback",
    "http://localhost:3000/auth/callback"
  ]
  
  logout_urls = [
    "https://www.devcloudproject.com",
    "http://localhost:3000"
  ]
}
