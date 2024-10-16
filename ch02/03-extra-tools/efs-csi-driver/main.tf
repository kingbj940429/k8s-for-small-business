locals {
  name = "sd-${terraform.workspace}-storage"

  azs = slice(data.aws_availability_zones.available.names, 0, 4)

  vpc_cidr_block     = "10.0.0.0/16"
  vpc_id             = data.aws_vpc.vpc.id
  private_subnet_ids = data.aws_subnets.private_subnets.ids
}

################################################################################
# EFS Module
################################################################################

module "efs" {
  source = "registry.terraform.io/terraform-aws-modules/efs/aws"
  version = "1.6.3"

  # File system
  name           = local.name
  creation_token = local.name
  encrypted      = false

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  # File system policy
  attach_policy = false
  bypass_policy_lockout_safety_check = false

  #-- AWS Backup Policy
  enable_backup_policy = false

  # Mount targets / security group
  mount_targets = {
    for k, v in toset(range(length(local.azs))) : element(local.azs, k) => {
      subnet_id = element(local.private_subnet_ids, k)
    }
  }

  security_group_description = "EFS security group"
  security_group_vpc_id      = local.vpc_id
  security_group_rules = {
    vpc = {
      description = "NFS ingress from VPC private subnets"
      cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    }
  }
}

################################################################################
# Data
################################################################################

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr_block
}

data "aws_subnets" "private_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    private = "true"
  }
}