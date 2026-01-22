variable "kubernetes_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.11" # Ensure this matches your requirements
}

variable "repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

# High Availability Configuration
variable "ha_enabled" {
  description = "Enable High Availability mode with multiple replicas"
  type        = bool
  default     = true
}

variable "controller_replicas" {
  description = "Number of ArgoCD application controller replicas (HA mode)"
  type        = number
  default     = 1
}

variable "server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 2
}

variable "repo_server_replicas" {
  description = "Number of ArgoCD repo server replicas"
  type        = number
  default     = 2
}

variable "redis_ha_enabled" {
  description = "Enable Redis HA for ArgoCD"
  type        = bool
  default     = true
}

# Resource Configuration
variable "controller_resources" {
  description = "Resource requests and limits for application controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "2Gi"
    }
  }
}

variable "server_resources" {
  description = "Resource requests and limits for ArgoCD server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "repo_server_resources" {
  description = "Resource requests and limits for repo server"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
  }
}

variable "dex_resources" {
  description = "Resource requests and limits for Dex (SSO)"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "50m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}

# Service Configuration
variable "server_service_type" {
  description = "Service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.server_service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable ingress for ArgoCD server"
  type        = bool
  default     = true
}

variable "ingress_enabled" {
  description = "Enable ingress (alias for backwards compatibility)"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class name (e.g., nginx, traefik)"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress hostname for ArgoCD"
  type        = string
  default     = "argocd.local"
}

variable "ingress_path" {
  description = "Ingress path"
  type        = string
  default     = "/"
}

variable "ingress_path_type" {
  description = "Ingress path type"
  type        = string
  default     = "Prefix"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "TLS secret name for ingress (leave empty for cert-manager)"
  type        = string
  default     = ""
}

variable "ingress_annotations" {
  description = "Additional annotations for ingress"
  type        = map(string)
  default = {
    "nginx.ingress.kubernetes.io/ssl-passthrough" = "false"
    "nginx.ingress.kubernetes.io/backend-protocol" = "HTTP"
    "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
  }
}

# Storage Configuration
variable "storage_class_name" {
  description = "Storage class for Redis persistent volumes (if Redis HA is enabled)"
  type        = string
  default     = ""
}

variable "redis_storage_size" {
  description = "Storage size for Redis persistent volume"
  type        = string
  default     = "8Gi"
}

# RBAC Configuration
variable "create_cluster_roles" {
  description = "Create cluster-level RBAC resources"
  type        = bool
  default     = true
}

# Admin Configuration
variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = true
}

variable "admin_password" {
  description = "ArgoCD admin password (bcrypt hash or plaintext - will be hashed)"
  type        = string
  sensitive   = true
  default     = ""
}

# Git Repository Configuration
variable "repositories" {
  description = "List of Git repositories to configure"
  type = list(object({
    url      = string
    name     = optional(string)
    type     = optional(string)
    username = optional(string)
    password = optional(string)
  }))
  default = []
}

# SSO Configuration
variable "dex_enabled" {
  description = "Enable Dex for SSO"
  type        = bool
  default     = false
}

variable "oidc_config" {
  description = "OIDC configuration for SSO"
  type = object({
    name          = optional(string)
    issuer        = optional(string)
    clientID      = optional(string)
    clientSecret  = optional(string)
    requestedScopes = optional(list(string))
  })
  default = {
    name          = ""
    issuer        = ""
    clientID      = ""
    clientSecret  = ""
    requestedScopes = []
  }
  sensitive = true
}

# Server Configuration
variable "insecure" {
  description = "Run server without TLS (useful behind ingress with TLS termination)"
  type        = bool
  default     = true
}

variable "extra_args" {
  description = "Extra arguments for ArgoCD server"
  type        = list(string)
  default     = []
}

# Metrics Configuration
variable "metrics_enabled" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "service_monitor_enabled" {
  description = "Enable ServiceMonitor for Prometheus Operator"
  type        = bool
  default     = false
}

# ApplicationSet Controller
variable "applicationset_enabled" {
  description = "Enable ApplicationSet controller"
  type        = bool
  default     = true
}

variable "applicationset_replicas" {
  description = "Number of ApplicationSet controller replicas"
  type        = number
  default     = 2
}

# Notifications Controller
variable "notifications_enabled" {
  description = "Enable notifications controller"
  type        = bool
  default     = false
}

# Additional Helm Values
variable "extra_values" {
  description = "Additional Helm values as YAML string"
  type        = string
  default     = ""
}

variable "extra_values_map" {
  description = "Additional Helm values as a map"
  type        = any
  default     = {}
}

# Image Configuration
variable "global_image_tag" {
  description = "Global image tag for all ArgoCD components (leave empty for chart default)"
  type        = string
  default     = ""
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

# Node Affinity and Tolerations
variable "node_selector" {
  description = "Node selector for all ArgoCD components"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for all ArgoCD components"
  type        = list(any)
  default     = []
}
