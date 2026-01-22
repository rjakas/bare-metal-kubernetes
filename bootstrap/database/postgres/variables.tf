variable "kubernetes_namespace" {
  type = string
}

variable "postgres_password" {
  type = string
  sensitive = true
}

variable "postgres_image" {
  type = string
  default = "postgres:14"
}

variable "storage_class_name" {
  type = string
}

variable "storage_size" {
  type = string
  default = "20Gi"
}