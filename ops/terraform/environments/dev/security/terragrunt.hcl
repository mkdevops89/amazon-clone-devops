# ops/terraform/environments/dev/security/terragrunt.hcl

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/security"
}

# Explicitly establish an infrastructure dependency sequence.
# Terragrunt guarantees the S3 buckets are built/checked FIRST,
# so their unique IDs can be safely passed into CloudTrail below.
dependency "storage" {
  config_path = "../s3"
  
  # Mock outputs so `terragrunt plan` doesn't crash if the S3 bucket hasn't been applied yet
  mock_outputs = {
    s3_evidence_bucket_id = "mock-s3-evidence-bucket-id"
  }
}

inputs = {
  environment              = "dev"
  project                  = "amazon-clone"
  
  # This boolean controls whether you pay ~$15/month for GuardDuty/Security Hub
  enable_ephemeral_soc     = false 
  
  # Inject the downstream bucket identifier
  evidence_bucket_id       = dependency.storage.outputs.s3_evidence_bucket_id
}
