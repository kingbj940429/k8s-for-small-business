data "aws_availability_zones" "available" {}

data "aws_iam_policy" "amazon_administrator_access_policy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

locals {
  name            = "dev-eks"
  cluster_version = "1.29"
  region          = "ap-northeast-2"

  vpc_cidr = "10.0.0.0/16"
  azs = slice(data.aws_availability_zones.available.names, 0, 4)

  tags = {
    Example = local.name
  }
}

################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.21.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = ["118.221.28.220/32"] #-- CIDR 를 통해 현재 IP 만 접근 가능하도록 설정

  cluster_addons = {
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    },
    vpc-cni = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

      configuration_values = jsonencode({
        enableNetworkPolicy = "true"
      })
    },
    aws-efs-csi-driver = {
      most_recent                 = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cloudwatch_log_group = false
  cluster_enabled_log_types = ["api", "audit"] # "authenticator", "controllerManager", "scheduler"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = module.karpenter_base_role.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }
  ]

  fargate_profiles = {
    karpenter = {
      selectors = [
        {
          namespace = "karpenter"
        }
      ]
    }
    #     kube-system = {
    #       selectors = [
    #         {
    #           namespace = "kube-system",
    #           labels = {
    #             "k8s-app" = "kube-dns"
    #           }
    #         }
    #       ]
    #     }
  }

  node_security_group_additional_rules = {
    http_allow = {
      description = "Allow HTTP inbound traffic"
      protocol    = "tcp"
      from_port   = 80
      to_port     = 80
      type        = "ingress"
      self        = true
    }

    https_allow = {
      description = "Allow HTTPS inbound traffic"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      self        = true
    }

    istio_allow = {
      description                   = "Allow Istio inbound traffic. This Rule is needed for istio validator"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  cluster_addons_timeouts = {
    create = "30m"
    update = "30m"
    delete = "10m"
  }

  cluster_timeouts = {
    create = "30m"
    update = "30m"
    delete = "10m"
  }

  tags = local.tags
}

################################################################################
# Karpenter
################################################################################

#-- Karpenter 에 의해 생성되는 Node 들이 기본적으로 가지는 Role
module "karpenter_base_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.41.0"

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  create_role             = true
  create_instance_profile = true

  role_name         = "KarpenterBaseInstanceRole"
  role_requires_mfa = false

  custom_role_policy_arns = [
    data.aws_iam_policy.amazon_administrator_access_policy.arn
  ]
}

#-- Karpenter Controller 가 가지는 IRSA
module "karpenter_base_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.41.0"

  create_role = true
  role_name   = "KarpenterBaseControllerIRSA"

  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = local.name
  karpenter_controller_node_iam_role_arns = [
    module.karpenter_base_role.iam_role_arn
  ]

  oidc_providers = {
    eks_issuer = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "karpenter:karpenter"
      ]
    }
  }
}

################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "karpenter.sh/discovery" = local.name
    public                   = "true"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = local.name
    private                           = "true"
  }

  tags = local.tags
}
