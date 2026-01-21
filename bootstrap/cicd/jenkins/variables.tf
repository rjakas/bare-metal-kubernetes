# basic configuration
variable "kubernetes_namespace" {
  description = "Namespace for Jenkins"
  type        = string
}

variable "release_name" {
  description = "Jenkins release name"
  type        = string
  default     = "jenkins"
}

# storage configuration
variable "storage_class_name" {
  description = "Storage class for Jenkins PVC"
  type        = string
}

variable "storage_size" {
  description = "Storage size for Jenkins home"
  type        = string
  default     = "20Gi"
}

# image configuration
variable "jenkins_image" {
  description = "Jenkins Docker image"
  type        = string
  default     = "jenkins/jenkins:lts"
}

# resource configuration
variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "500m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "2000m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "1Gi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "4Gi"
}

variable "java_opts" {
  description = "Java options for Jenkins"
  type        = string
  default     = "-Xmx2048m -Xms1024m"
}

# admin configuration
variable "admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

# NOTE: Plugins are now managed via Ansible playbook (ansible/playbooks/jenkins-init-container.yml)

# ingress configuration
variable "enable_ingress" {
  description = "Enable ingress for Jenkins"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress hostname for Jenkins"
  type        = string
  default     = "jenkins.local"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "jenkins-tls"
}

variable "ingress_annotations" {
  description = "Additional annotations for ingress"
  type        = map(string)
  default     = {}
}

# backup configuration
variable "enable_backup" {
  description = "Enable automated backups using CronJob"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Cron schedule for backups (e.g., '0 2 * * *' for daily at 2 AM)"
  type        = string
  default     = "0 2 * * *"
}

variable "volume_snapshot_class" {
  description = "VolumeSnapshotClass name for PVC snapshots"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "backup_storage_location" {
  description = "S3/GCS bucket for backup storage (optional)"
  type        = string
  default     = ""
}

# monitoring configuration
variable "enable_prometheus" {
  description = "Enable Prometheus ServiceMonitor"
  type        = bool
  default     = false
}

variable "prometheus_namespace" {
  description = "Namespace where Prometheus Operator is installed"
  type        = string
  default     = "monitoring"
}
