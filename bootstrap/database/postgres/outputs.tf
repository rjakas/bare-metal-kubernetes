output "postgres_service_name" {
  value = kubernetes_service_v1.postgres_service.metadata[0].name
}

output "postgres_stateful_set_name" {
  value = kubernetes_stateful_set_v1.postgres_stateful_set.metadata[0].name
}

