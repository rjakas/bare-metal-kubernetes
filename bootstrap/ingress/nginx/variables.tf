# basic configuration
variable "kubernetes_namespace" {
  type = string
}

variable "ingress_nginx_name" {
  type = string
}

variable "ingress_nginx_replica_count" {
  type = number
}

variable "ingress_nginx_service_type" {
  type = string
  validation {
    condition = contains(["LoadBalancer", "ClusterIP"], var.ingress_nginx_service_type)
    error_message = "Invalid service type."
  }
}

# resource configuration
variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}