locals {
  name      = "istio-gateway"
  namespace = "istio-system"
}

resource "helm_release" "istio_gateway" {
  name      = local.name
  namespace = local.namespace

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.18.2"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 300

  values = [
    file("${path.module}/override-values.yaml")
  ]

}
