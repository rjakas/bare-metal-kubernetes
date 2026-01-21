variable "kubernetes_api_host" {
  type = string
  description = "URL of kubernetes API. Example: https://127.0.0.1:36375, use kubectl cluster-info"
}

variable "client_certificate" {
  type = string
  description = "Cluster client-certificate-data, use kubectl config view"
}

variable "client_key" {
  type = string
  description = "Cluster client-key-data, use kubectl config view"
}

variable "cluster_ca_certificate" {
  type = string
  description = "Cluster certificate-authority-data, use kubectl config view"
}