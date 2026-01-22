### namespaces ###
module "ns-global" {
  source = "./bootstrap/kubernetes/namespace"
  kubernetes_namespace = "global"

  providers = {
    kubernetes = kubernetes
  }
}
module "ns-devops" {
  source = "./bootstrap/kubernetes/namespace"
  kubernetes_namespace = "devops"

  providers = {
    kubernetes = kubernetes
  }
}
module "ns-postgres" {
  source = "./bootstrap/kubernetes/namespace"
  kubernetes_namespace = "postgres"

  providers = {
    kubernetes = kubernetes
  }
}
### storage classes ###
module "storage-class-primary" {
  source = "./bootstrap/kubernetes/storage"

  storage_class_name = "storage-class-primary"
  storage_class_volume_binding_mode = "WaitForFirstConsumer" # ! DEV ! 
  storage_class_reclaim_policy = "Delete"

  providers = {
    kubernetes = kubernetes
  }
  depends_on = [ module.ns-global ]
}
### load balancer ###
module "metallb" {
  source = "./bootstrap/kubernetes/metallb"
  kubernetes_namespace = module.ns-global.kubernetes_namespace

  providers = {
    kubernetes = kubernetes
    helm = helm
    kubectl = kubectl
    null = null
  }
  depends_on = [ module.ns-global ]
}

### ingress controllers ### 
module "ingress-nginx-primary" {
  source = "./bootstrap/ingress/nginx"

  kubernetes_namespace = module.ns-global.kubernetes_namespace
  
  ingress_nginx_name = "ingress-nginx"
  ingress_nginx_replica_count = 2
  ingress_nginx_service_type = "LoadBalancer"

  providers = {
    helm = helm
  }
  depends_on = [ module.ns-global ]
}