terraform {
  required_version = "~> 1.0"

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.1"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.13"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.8"
    }
  }
}

provider "kubernetes" {
  host = var.kubernetes_api_host
  client_certificate = base64decode(var.client_certificate)
  client_key = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

provider "helm" {
  kubernetes = {
    host = var.kubernetes_api_host
    client_certificate = base64decode(var.client_certificate)
    client_key = base64decode(var.client_key)
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host = var.kubernetes_api_host
  client_certificate = base64decode(var.client_certificate)
  client_key = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  load_config_file = "false"
}

provider "time" {}
provider "null" {}
provider "random" {}