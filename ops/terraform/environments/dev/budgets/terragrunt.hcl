include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../modules/budgets"
}

inputs = {
  project              = "amazon-clone"
  environment          = "dev"
  alerts_sns_topic_arn = "arn:aws:sns:us-east-1:406312601212:amazon-clone-dev-alerts" # Default placeholder based on architecture
}
