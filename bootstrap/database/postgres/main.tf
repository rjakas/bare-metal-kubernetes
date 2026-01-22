terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

resource "kubernetes_secret_v1" "postgres_password" {
  metadata {
    name = "postgres-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    password = base64encode(var.postgres_password)
  }

  type = "Opaque"
}

resource "kubernetes_service_v1" "postgres_service" {
  metadata {
    name = "postgres"
    namespace = var.kubernetes_namespace
  }

  spec {
    cluster_ip = "None"

    selector = {
      app = "postgres"
    }

    port {
      port = 5432
      target_port = 5432
      name = "postgres"
    }
  }
}

resource "kubernetes_stateful_set_v1" "postgres_stateful_set" {
  metadata {
    name = "postgres"
    namespace = var.kubernetes_namespace
  }

  spec {
    service_name = "postgres"
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name = "postgres"
          image = var.postgres_image

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.postgres_password.metadata[0].name
                key = "password"
              }
            }
          }

          env {
            name = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          port {
            container_port = 5432
            name = "postgres"
          }

          volume_mount {
            name = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              cpu = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu = "1000m"
              memory = "2Gi"
            }
          }

          liveness_probe {
            exec {
              command = [ "pg_isready", "-U", "postgres" ]
            }
            initial_delay_seconds = 30
            period_seconds = 10
          }

          readiness_probe {
            exec {
              command = [ "pg_isready", "-U", "postgres" ] 
            }
            initial_delay_seconds = 10
            period_seconds = 5
          }

        }
      }
    }

    volume_claim_template {
      metadata {
        name = "postgres-data"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        storage_class_name = var.storage_class_name

        resources {
          requests = {
            storage = var.storage_size
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.postgres_password,
    kubernetes_service_v1.postgres_service
   ]
}