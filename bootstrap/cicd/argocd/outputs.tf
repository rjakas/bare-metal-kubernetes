output "namespace" {
  description = "ArgoCD namespace"
  value       = local.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "release_version" {
  description = "Helm chart version"
  value       = helm_release.argocd.version
}

output "release_status" {
  description = "Helm release status"
  value       = helm_release.argocd.status
}

output "server_service_name" {
  description = "ArgoCD server service name"
  value       = "${var.release_name}-server"
}

output "server_service_type" {
  description = "ArgoCD server service type"
  value       = var.server_service_type
}

output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = local.ingress_enabled
}

output "ingress_host" {
  description = "ArgoCD ingress hostname"
  value       = local.ingress_enabled ? var.ingress_host : null
}

output "ingress_url" {
  description = "ArgoCD URL (via ingress or port-forward instructions)"
  value       = local.ingress_enabled ? "${var.enable_tls ? "https" : "http"}://${var.ingress_host}" : "Port-forward: kubectl port-forward -n ${local.namespace} svc/${var.release_name}-server 8080:443"
}

output "admin_username" {
  description = "ArgoCD admin username"
  value       = var.admin_enabled ? "admin" : null
}

output "admin_password_command" {
  description = "Command to retrieve ArgoCD admin password"
  value       = var.admin_enabled && var.admin_password == "" ? "kubectl -n ${local.namespace} get secret ${var.release_name}-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : "Password set via variable"
}

output "ha_enabled" {
  description = "Whether High Availability mode is enabled"
  value       = var.ha_enabled
}

output "redis_ha_enabled" {
  description = "Whether Redis HA is enabled"
  value       = var.redis_ha_enabled && var.ha_enabled
}

output "server_replicas" {
  description = "Number of ArgoCD server replicas"
  value       = var.server_replicas
}

output "repo_server_replicas" {
  description = "Number of repo server replicas"
  value       = var.repo_server_replicas
}

output "applicationset_enabled" {
  description = "Whether ApplicationSet controller is enabled"
  value       = var.applicationset_enabled
}

output "metrics_enabled" {
  description = "Whether Prometheus metrics are enabled"
  value       = var.metrics_enabled
}

output "dex_enabled" {
  description = "Whether Dex SSO is enabled"
  value       = var.dex_enabled
}
