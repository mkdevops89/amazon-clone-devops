terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  backend "s3" {
    bucket         = "amazon-clone-tfstate-406312601212"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "amazon-clone-tf-locks"
    encrypt        = true
  }
}
