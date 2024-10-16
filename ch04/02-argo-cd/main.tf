locals {
  domain = "argo.kingbj0429.com"

  name = "argo"
  namespace = "continuous-system"
}

resource "helm_release" "argo" {
  name      = local.name
  namespace = local.namespace

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.18"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 120

  values = [
    file("${path.module}/override-values.yaml")
  ]

  set {
    name  = "fullnameOverride"
    value = local.name
  }

}
