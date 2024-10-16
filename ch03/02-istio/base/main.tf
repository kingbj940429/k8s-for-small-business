locals {
  name      = "istio-base"
  namespace = "istio-system"
}

resource "helm_release" "istio_base" {
  name      = local.name
  namespace = local.namespace

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.18.2"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 600

}
