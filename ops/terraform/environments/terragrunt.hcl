# ops/terraform/environments/terragrunt.hcl

# Pin the AWS provider version to 5.x globally to avoid breaking API changes in 6.0
generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}

# Generate the AWS provider block automatically for all child modules
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Project     = "Amazon-Clone-DevSecOps"
      ManagedBy   = "Terragrunt"
      Environment = "dev"
    }
  }
}
EOF
}

# Automatically configure the S3 backend for all child modules
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "amazon-clone-tfstate-406312601212"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "amazon-clone-tf-locks"
    encrypt        = true
  }
}
