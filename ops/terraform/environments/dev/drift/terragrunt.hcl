include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/drift"
}

inputs = {
  project              = "amazon-clone"
  environment          = "dev"
  sns_topic_arn        = "arn:aws:sns:us-east-1:406312601212:amazon-clone-dev-alerts" 
}
