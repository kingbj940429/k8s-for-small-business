locals {
  node_set_name_prefix = "karpenter.sh"

  node_set_name = {
    default           = "default"
    istio             = "istio"
  }
}

################################################################################
# Default Node Set
################################################################################

resource "kubernetes_manifest" "default_ec2_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"

    metadata = {
      name = local.node_set_name.default
    }

    spec = {
      amiFamily = "AL2"

      subnetSelectorTerms = [
        for subnet in data.aws_subnets.subnets.ids : {
          id = subnet
        }
      ]

      securityGroupSelectorTerms = [
        { id = data.aws_security_group.eks_node_sg.id }
      ]

      instanceProfile = local.karpenter_base_instance_role_name

      tags = {
        Name                     = "${local.node_set_name_prefix}/${local.node_set_name.default}"
        "karpenter.sh/discovery" = data.aws_eks_cluster.eks.name
      }

      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs        = {
            volumeSize          = "50Gi"
            volumeType          = "gp2"
            encrypted           = "false"
            deleteOnTermination = "true"
          }
        }
      ]

      detailedMonitoring = "false"
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "default_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"

    metadata = {
      name = local.node_set_name.default
    }

    spec = {
      template = {
        metadata = {
          annotations = merge()
        }

        spec = {
          nodeClassRef = {
            name = local.node_set_name.default
          }

          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["t3"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["medium", "large", "xlarge", "2xlarge"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]
        }
      }

      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }

      limits = {
        cpu    = "1000"
        memory = "1000Gi"
      }

      weight = "10"
    }
  }

  depends_on = [helm_release.karpenter]
}

################################################################################
# Only Istio Node Set
################################################################################

resource "kubernetes_manifest" "istio_ec2_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"

    metadata = {
      name = local.node_set_name.istio
    }

    spec = {
      amiFamily = "AL2"

      subnetSelectorTerms = [
        for subnet in data.aws_subnets.subnets.ids : {
          id = subnet
        }
      ]

      securityGroupSelectorTerms = [
        { id = data.aws_security_group.eks_node_sg.id }
      ]

      instanceProfile = local.karpenter_base_instance_role_name

      tags = {
        Name                     = "${local.node_set_name_prefix}/${local.node_set_name.istio}"
        "karpenter.sh/discovery" = data.aws_eks_cluster.eks.name
      }

      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs        = {
            volumeSize          = "30Gi"
            volumeType          = "gp2"
            encrypted           = "false"
            deleteOnTermination = "true"
          }
        }
      ]

      detailedMonitoring = "true"
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "istio_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"

    metadata = {
      name = local.node_set_name.istio
    }

    spec = {
      template = {
        metadata = {
          labels = {
            "elbv2.target.io/discovery" = data.aws_eks_cluster.eks.name
          }

          annotations = merge()
        }

        spec = {
          nodeClassRef = {
            name = local.node_set_name.istio
          }

          taints = [
            {
              key    = "k8s.kingbj0429.in/node-usage-type"
              value  = "istio"
              effect = "NoExecute"
            }
          ]

          requirements = [
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["t3"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values   = ["medium", "large", "xlarge"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c", "ap-northeast-2d"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            }
          ]

          kubelet = {
            imageGCHighThresholdPercent = 50
            imageGCLowThresholdPercent  = 40
          }
        }
      }

      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }

      limits = {
        cpu    = "50"
        memory = "250Gi"
      }

      weight = "10"
    }
  }

  depends_on = [helm_release.karpenter]
}
