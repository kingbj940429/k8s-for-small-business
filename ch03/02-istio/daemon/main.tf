locals {
  name      = "istiod"
  namespace = "istio-system"
}

resource "helm_release" "istiod" {
  name      = local.name
  namespace = local.namespace

  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.18.2"

  atomic           = true
  wait             = true
  create_namespace = true
  max_history      = 10
  timeout          = 600

  values = [
    file("${path.module}/override-values.yaml")
  ]

  set {
    name  = "global.proxy.privileged"
    value = "true"
  }

  set {
    name  = "sidecarInjectorWebhook.enableNamespacesByDefault"
    value = "true"
  }

  set {
    name  = "telemetry.enabled"
    value = "false"
  }

  set {
    name  = "pilot.podLabels.version"
    value = "latest"
  }

}
