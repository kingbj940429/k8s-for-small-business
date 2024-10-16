locals {
  cluster_name = "dev-eks"

  name      = "aws-lb-controller"
  namespace = "kube-system"

  vpc_cidr_block = "10.0.0.0/16"

  oidc_url_without_protocol = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_url_without_protocol}"
}

resource "helm_release" "aws_lb_controller" {
  name      = local.name
  namespace = local.namespace

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.1"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 180

  values = [
    file("${path.module}/override-values.yaml")
  ]

  set {
    name  = "fullnameOverride"
    value = local.name
  }

  set {
    name  = "clusterName"
    value = data.aws_eks_cluster.eks.name
  }

  set {
    name  = "region"
    value = "ap-northeast-2"
  }

  set {
    name  = "vpcId"
    value = data.aws_vpc.vpc.id
  }

  set {
    name  = "enableCertManager"
    value = "false"
  }

  set {
    name  = "enableShield"
    value = "false"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.load_balancer_controller_irsa_role.iam_role_arn
  }
}

module "load_balancer_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.41.0"

  role_name                              = "LoadBalancerControllerIRSA"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn = local.oidc_arn
      namespace_service_accounts = ["${local.namespace}:${local.name}"]
    }
  }
}

################################################################################
# Existing resources
################################################################################
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

data "aws_subnets" "public_subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    public = "true"
  }
}


data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}