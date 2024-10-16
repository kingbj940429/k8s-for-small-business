terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    key     = "tfstates/ch02/02-eks.tfstate"
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

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", "small-business-with-k8s"]
  }
}

