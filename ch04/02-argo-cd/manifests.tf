################################################################################
# Istio
################################################################################
resource "kubernetes_manifest" "virtual_service" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata"   = {
      "name"      = "${local.name}-virtual-service"
      "namespace" = local.namespace
    }

    "spec" = {
      "hosts" = [
        local.domain
      ]

      "gateways" = [
        "istio-system/default"
      ]

      "http" = [
        {
          "route" = [
            {
              "destination" = {
                "host"   = "${local.name}-server"
                "subset" = "stable"
                port = {
                  number = 80
                }
              }

              "weight" = 100
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "destination_rule" {
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "DestinationRule"
    "metadata"   = {
      "name"      = "${local.name}-destination-rule"
      "namespace" = local.namespace
    }

    "spec" = {
      "host" = "${local.name}-server"

      "subsets" = [
        {
          "name" = "stable"
        }
      ]
    }
  }
}

################################################################################
# Argo Application for App of Apps Pattern
################################################################################

resource "kubernetes_manifest" "app_of_apps" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "root-apps"
      namespace = local.namespace
    }

    spec = {
      destination = {
        namespace = local.namespace
        server    = "https://kubernetes.default.svc"
      }

      project = "default"

      source = {
        path           = "app-of-apps/apps/.bootstraps"
        repoURL        = "git@github.com:kingbj940429/small-business-with-k8s.git"
        targetRevision = "main"
        directory      = {
          recurse = true
        }
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }

  depends_on = [
    helm_release.argo
  ]
}
