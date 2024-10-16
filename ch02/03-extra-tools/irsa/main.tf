locals {
  cluster_name = "dev-eks"
  name         = "MyAppIRSA"

  oidc_url_without_protocol = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_url_without_protocol}"
}

module "irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name              = local.name
  allow_self_assume_role = true

  oidc_providers = {
    one = {
      provider_arn = local.oidc_arn
      namespace_service_accounts = ["default:my-app"]
    }
  }

  role_policy_arns = {
    additional = module.iam_policy.arn
  }
}

module "iam_policy" {
  source = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "myapp"
  path        = "/"
  description = "Example policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
        ]
        Resource = "*"
      }
    ]
  })
}

################################################################################
# Existing resources
################################################################################
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}
