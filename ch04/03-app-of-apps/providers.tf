terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    key     = "tfstates/ch04/03-app-of-apps.tfstate"
    bucket  = "small-business-with-k8s-tf-state"
    profile = "small-business-with-k8s"
    region  = "ap-northeast-2"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.58.0"
    }
  }
}

provider "aws" {
  profile = "small-business-with-k8s"
  region  = "ap-northeast-2"

  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]

  default_tags {
    tags = {
      terraform   = "true"
      environment = terraform.workspace
    }
  }
}
