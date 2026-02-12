terraform {
  backend "s3" {
    bucket         = "amazon-clone-tfstate-406312601212"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "amazon-clone-tf-locks"
    encrypt        = true
  }
}
