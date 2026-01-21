output "kubernetes_namespace" {
  description = "Kubernetes namespace name"
  value = kubernetes_namespace_v1.kubernetes_namespace.metadata[0].name
}