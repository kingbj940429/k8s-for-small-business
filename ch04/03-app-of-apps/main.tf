locals {
  cluster_name = "dev-eks"
  name         = "dev-secrets-manager"

  oidc_url_without_protocol = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
  oidc_arn                  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_url_without_protocol}"
}

module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.1.1"

  # Secret
  name                    = local.name
  description             = "Dev Secrets Manager secret"
  recovery_window_in_days = 0

  # Policy
  create_policy       = false
  block_public_policy = true

  # Version
  create_random_password = false
  secret_string          = jsonencode({})
}

module "argo_cd_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.41.0"

  role_name              = "ArgoCDIRSA"
  allow_self_assume_role = true

  oidc_providers = {
    one = {
      provider_arn               = local.oidc_arn
      namespace_service_accounts = ["continuous-system:argo-repo-server"]
    }
  }

  role_policy_arns = {
    argo_cd_irsa_role_policy = module.argo_cd_irsa_role_policy.arn
  }
}

module "argo_cd_irsa_role_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.41.0"

  name        = local.name
  description = "For argo-cd irsa policy"

  policy = data.aws_iam_policy_document.argo_cd_irsa_role_policy.json
}

data "aws_iam_policy_document" "argo_cd_irsa_role_policy" {
  statement {
    sid       = "ArgoCDIRSAPolicy0"
    effect    = "Allow"
    actions   = ["secretsmanager:*"]
    resources = ["*"]
  }
}

################################################################################
# Existing resources
################################################################################
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = local.cluster_name
}