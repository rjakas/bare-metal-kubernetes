terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }
}

# Namespace for ArgoCD
resource "kubernetes_namespace_v1" "argocd" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.kubernetes_namespace

    labels = {
      name = var.kubernetes_namespace
      "app.kubernetes.io/name" = "argocd"
    }
  }
}

# Local values for computed configurations
locals {
  namespace = var.create_namespace ? kubernetes_namespace_v1.argocd[0].metadata[0].name : var.kubernetes_namespace

  # Determine if ingress is actually enabled
  ingress_enabled = var.enable_ingress && var.ingress_enabled

  # Base ingress annotations
  base_ingress_annotations = {
    "nginx.ingress.kubernetes.io/ssl-passthrough"     = "false"
    "nginx.ingress.kubernetes.io/backend-protocol"    = "HTTP"
    "nginx.ingress.kubernetes.io/force-ssl-redirect"  = var.enable_tls ? "true" : "false"
  }

  # Merge base and custom ingress annotations
  ingress_annotations = merge(local.base_ingress_annotations, var.ingress_annotations)

  # Construct TLS configuration
  tls_config = var.enable_tls ? [{
    hosts       = [var.ingress_host]
    secretName  = var.tls_secret_name != "" ? var.tls_secret_name : "${var.release_name}-tls"
  }] : []

  # Build values for Helm chart
  helm_values = {
    global = merge(
      var.global_image_tag != "" ? { image = { tag = var.global_image_tag } } : {},
      {
        imagePullPolicy = var.image_pull_policy
      }
    )

    # Controller configuration
    controller = {
      replicas = var.controller_replicas
      resources = {
        requests = {
          cpu    = var.controller_resources.requests.cpu
          memory = var.controller_resources.requests.memory
        }
        limits = {
          cpu    = var.controller_resources.limits.cpu
          memory = var.controller_resources.limits.memory
        }
      }
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      metrics = {
        enabled = var.metrics_enabled
        serviceMonitor = {
          enabled = var.service_monitor_enabled
        }
      }
    }

    # Server configuration
    server = {
      replicas = var.server_replicas
      autoscaling = {
        enabled = false
      }
      resources = {
        requests = {
          cpu    = var.server_resources.requests.cpu
          memory = var.server_resources.requests.memory
        }
        limits = {
          cpu    = var.server_resources.limits.cpu
          memory = var.server_resources.limits.memory
        }
      }
      service = {
        type = var.server_service_type
      }
      ingress = {
        enabled          = local.ingress_enabled
        ingressClassName = var.ingress_class
        annotations      = local.ingress_annotations
        hosts            = [var.ingress_host]
        paths            = [var.ingress_path]
        pathType         = var.ingress_path_type
        tls              = local.tls_config
      }
      insecure         = var.insecure
      extraArgs        = var.extra_args
      nodeSelector     = var.node_selector
      tolerations      = var.tolerations
      metrics = {
        enabled = var.metrics_enabled
        serviceMonitor = {
          enabled = var.service_monitor_enabled
        }
      }
    }

    # Repo server configuration
    repoServer = {
      replicas = var.repo_server_replicas
      autoscaling = {
        enabled = false
      }
      resources = {
        requests = {
          cpu    = var.repo_server_resources.requests.cpu
          memory = var.repo_server_resources.requests.memory
        }
        limits = {
          cpu    = var.repo_server_resources.limits.cpu
          memory = var.repo_server_resources.limits.memory
        }
      }
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      metrics = {
        enabled = var.metrics_enabled
        serviceMonitor = {
          enabled = var.service_monitor_enabled
        }
      }
    }

    # Redis HA configuration
    redis-ha = {
      enabled = var.redis_ha_enabled && var.ha_enabled
      persistentVolume = {
        enabled      = var.redis_ha_enabled && var.ha_enabled
        storageClass = var.storage_class_name != "" ? var.storage_class_name : null
        size         = var.redis_storage_size
      }
    }

    # Redis (single instance, used when HA is disabled)
    redis = {
      enabled = !var.redis_ha_enabled || !var.ha_enabled
    }

    # Dex (SSO) configuration
    dex = {
      enabled = var.dex_enabled
      resources = {
        requests = {
          cpu    = var.dex_resources.requests.cpu
          memory = var.dex_resources.requests.memory
        }
        limits = {
          cpu    = var.dex_resources.limits.cpu
          memory = var.dex_resources.limits.memory
        }
      }
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
    }

    # ApplicationSet controller
    applicationSet = {
      enabled  = var.applicationset_enabled
      replicas = var.applicationset_replicas
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      metrics = {
        enabled = var.metrics_enabled
        serviceMonitor = {
          enabled = var.service_monitor_enabled
        }
      }
    }

    # Notifications controller
    notifications = {
      enabled = var.notifications_enabled
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
    }

    # RBAC configuration
    createClusterRoles = var.create_cluster_roles

    # Config map for ArgoCD configuration
    configs = merge(
      var.admin_password != "" ? {
        secret = {
          argocdServerAdminPassword = var.admin_password
        }
      } : {},
      length(var.repositories) > 0 ? {
        repositories = { for idx, repo in var.repositories :
          repo.name != null ? repo.name : "repo-${idx}" => {
            url      = repo.url
            type     = repo.type != null ? repo.type : "git"
            username = repo.username
            password = repo.password
          }
        }
      } : {},
      var.oidc_config.issuer != "" ? {
        cm = {
          "oidc.config" = yamlencode({
            name          = var.oidc_config.name
            issuer        = var.oidc_config.issuer
            clientID      = var.oidc_config.clientID
            clientSecret  = var.oidc_config.clientSecret
            requestedScopes = var.oidc_config.requestedScopes
          })
        }
      } : {}
    )
  }

  # Merge with extra values
  final_helm_values = merge(local.helm_values, var.extra_values_map)
}

# ArgoCD Helm Release
resource "helm_release" "argocd" {
  name       = var.release_name
  repository = var.repository
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = local.namespace

  values = [
    yamlencode(local.final_helm_values),
    var.extra_values
  ]

  # Ensure namespace is created before deploying
  depends_on = [
    kubernetes_namespace_v1.argocd
  ]

  # Timeout for installation (ArgoCD can take time to start)
  timeout = 600

  # Atomic installation - rollback on failure
  atomic = true

  # Clean up on delete
  cleanup_on_fail = true

  # Wait for resources to be ready
  wait = true
}
