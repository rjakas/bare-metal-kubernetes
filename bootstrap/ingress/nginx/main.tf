terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

resource "helm_release" "ingress_nginx" {
  name = var.ingress_nginx_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart = "ingress-nginx"
  version = "4.8.3"
  namespace = var.kubernetes_namespace


  # DEV ONLY: Do not wait for ready status - let it run in bg
  timeout = 300 # timeout reduction
  wait = true
  wait_for_jobs = "false"


  set = [ 
  # CRITICAL: Disable admission webhooks, re-visit for implications
  {
    name = "controller.admissionWebhooks.enabled"
    value = "false"
  }
  ,
  {
    name = "controller.admissionWebhooks.patch.enabled"
    value = "false"
  }
  ,
  {
    name = "controller.admissionWebhooks.createSecretJob.enabled"
    value = "false"
  }
  ,
  {
    name = "controller.admissionWebhooks.patchWebhookJob.enabled"
    value = "false"
  }
  ,
  # core controller config
  {
    name = "controller.replicaCount"
    value = var.ingress_nginx_replica_count  
  }
  ,
  {
    name = "controller.service.type"
    value = var.ingress_nginx_service_type
  }
  ,
  # resource limits
  {
    name = "controller.resources.requests.cpu",
    value = var.cpu_request
  }
  ,
  {
    name = "controller.resources.requests.memory",
    value = var.memory_request
  }
  ,
  {
    name = "controller.resources.limits.cpu"
    value = var.cpu_limit
  }
  ,
  {
    name = "controller.resources.limits.memory"
    value = var.memory_limit
  },
  # metrics and monitoring
  {
    name = "controller.metrics.enabled"
    value = "false"
  }
  ,
  {
    name = "controller.metrics.serviceMonitor.enabled"
    value = "false"
    # set true if prometheus operator is desired to be installed
  }
  ]
}

