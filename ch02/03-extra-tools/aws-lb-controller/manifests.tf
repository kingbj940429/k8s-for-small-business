locals {
  ingress_namespace = "istio-system"

  ingress_name = "aws-alb-ingress"

  tls_hosts = ["kingbj0429.com", "*.kingbj0429.com"]
}

################################################################################
# AWS Internal ALB Ingress
################################################################################
resource "kubernetes_ingress_v1" "aws_alb_ingress" {
  metadata {
    name      = local.ingress_name
    namespace = local.ingress_namespace

    annotations = {
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"        = "instance"
      "alb.ingress.kubernetes.io/load-balancer-name" = local.ingress_name
      "alb.ingress.kubernetes.io/listen-ports"       = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
      "alb.ingress.kubernetes.io/certificate-arn"    = "arn:aws:acm:ap-northeast-2:025066270378:certificate/3a57c09c-e725-43ce-abef-5e568d29fc48, arn:aws:acm:ap-northeast-2:025066270378:certificate/80a50c74-7bda-4a82-a1ea-455b4a0875c5"
      "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
      "alb.ingress.kubernetes.io/inbound-cidrs"      = "118.221.28.220/32"
      "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "alb.ingress.kubernetes.io/target-node-labels" = "elbv2.target.io/discovery=${data.aws_eks_cluster.eks.name}"
      "alb.ingress.kubernetes.io/subnets"            = join(",", data.aws_subnets.public_subnets.ids)

      # -- Attributes
      "alb.ingress.kubernetes.io/load-balancer-attributes" = "idle_timeout.timeout_seconds=60"

      # -- Security Group
      "alb.ingress.kubernetes.io/manage-backend-security-group-rules" = "true"

      # -- Health Check
      "alb.ingress.kubernetes.io/healthcheck-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port"     = "32001"
      "alb.ingress.kubernetes.io/healthcheck-path"     = "/healthz/ready"
    }

    labels = {
      app = local.ingress_name
    }
  }

  spec {
    ingress_class_name = "alb"

    tls {
      hosts = local.tls_hosts
    }

    rule {
      http {
        path {
          backend {
            service {
              name = "istio-gateway"
              port {
                number = 80
              }
            }
          }

          path      = "/"
          path_type = "Prefix"
        }
      }
    }
  }
}
