locals {
  cluster_name = "dev-eks"

  vpc_cidr_block = "10.0.0.0/16"
  eks_node_sg_id = "sg-0425cacecacedf956"

  karpenter_controller_irsa_name    = "KarpenterBaseControllerIRSA"
  karpenter_base_instance_role_name = "KarpenterBaseInstanceRole"

  karpenter_sa_name   = "karpenter"
  karpenter_namespace = "karpenter"
}

################################################################################
# Helm Karpenter
################################################################################

resource "helm_release" "karpenter" {
  name      = "karpenter"
  namespace = local.karpenter_namespace

  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.35.5"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 180

  values = [
    file("${path.module}/override-values.yaml")
  ]

  set {
    name  = "settings.clusterName"
    value = data.aws_eks_cluster.eks.name
  }

  set {
    name  = "serviceAccount.name"
    value = local.karpenter_sa_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.aws_iam_role.karpenter_base_controller_role.arn
  }
}

################################################################################
# Existing resources
################################################################################

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}

data "aws_iam_role" "karpenter_base_instance_role" {
  name = local.karpenter_base_instance_role_name
}

data "aws_iam_role" "karpenter_base_controller_role" {
  name = local.karpenter_controller_irsa_name
}

data "aws_vpc" "vpc" {
  cidr_block = local.vpc_cidr_block
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    private = "true"
  }
}

data "aws_security_group" "eks_node_sg" {
  id = local.eks_node_sg_id
}
