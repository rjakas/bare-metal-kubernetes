terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

resource "helm_release" "metallb_system" {
  name = var.metallb_name
  repository = var.metallb_repository
  chart = var.metallb_chart_name
  version = var.metallb_version

  namespace = var.kubernetes_namespace

  # ! DEV ONLY !
  wait = "false"
  timeout = 300
  cleanup_on_fail = "false"
}

# Wait for webook deployment to be ready
resource "null_resource" "wait_for_metallb_webhook" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for MetalLB webhook deployment..."
      
      # Wait for webhook deployment
      kubectl wait --namespace ${var.kubernetes_namespace} \
        --for=condition=available \
        --timeout=120s \
        deployment/metallb-webhook-service || true
      
      # Wait for webhook pods to be ready
      kubectl wait --namespace ${var.kubernetes_namespace} \
        --for=condition=ready pod \
        --selector=component=webhook \
        --timeout=120s || true
      
      # Give webhook extra time to register with API server
      echo "Webhook pods ready, waiting for webhook registration..."
      sleep 15
      
      echo "MetalLB webhook should be ready now"
    EOT
  }
}

resource "kubectl_manifest" "metallb_ippool" {
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "default-pool"
      namespace = var.kubernetes_namespace
    }
    spec = {
      addresses = var.metallb_ippool
    }
  })

  depends_on = [null_resource.wait_for_metallb_webhook]
}

resource "kubectl_manifest" "metallb_l2advertisement" {
  yaml_body = yamlencode({
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "default"
      namespace = var.kubernetes_namespace
    }
    spec = {
      ipAddressPools = ["default-pool"]
    }
  })

  depends_on = [kubectl_manifest.metallb_ippool]
}