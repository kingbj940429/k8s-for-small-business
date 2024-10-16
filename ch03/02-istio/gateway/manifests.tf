locals {
  gateway_name = {
    default = "default"
  }

  hosts =["kingbj0429.com", "*.kingbj0429.com"]
}

resource "kubernetes_manifest" "default_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"

    metadata = {
      name      = local.gateway_name.default
      namespace = local.namespace
    }

    spec = {
      selector = {
        istio = "gateway"
      }

      servers = [
        {
          hosts = local.hosts

          port = {
            name     = "http"
            number   = 80
            protocol = "HTTP"
          }
        }
      ]

    }
  }
}
