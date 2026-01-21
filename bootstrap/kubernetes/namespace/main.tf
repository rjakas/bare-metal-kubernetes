terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_namespace_v1" "kubernetes_namespace" {
  metadata {
    name = var.kubernetes_namespace
  }
}