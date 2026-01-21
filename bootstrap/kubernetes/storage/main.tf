terraform {
  required_providers {
    kubernetes = {
        source = "hashicorp/kubernetes"
    }
  }
}


# Dynamic storage class
resource "kubernetes_storage_class_v1" "storage_class" {
  metadata {
    name = var.storage_class_name
  }
  
  storage_provisioner = var.storage_class_provisioner
  reclaim_policy = var.storage_class_reclaim_policy
  volume_binding_mode = var.storage_class_volume_binding_mode
}