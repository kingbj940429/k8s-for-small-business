terraform {
  required_version = ">= 1.9.0"

  backend "s3" {
    key     = "tfstates/ch03/03-aws-lb-controller.tfstate"
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

    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
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

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "arn:aws:eks:ap-northeast-2:025066270378:cluster/dev-eks"
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "arn:aws:eks:ap-northeast-2:025066270378:cluster/dev-eks"
}
