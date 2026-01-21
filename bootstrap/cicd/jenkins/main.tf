terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# ConfigMap for Ansible initialization playbook
resource "kubernetes_config_map_v1" "jenkins_ansible_config" {
  metadata {
    name      = "${var.release_name}-ansible"
    namespace = var.kubernetes_namespace
  }

  data = {
    "jenkins-init.yml" = file("${path.root}/ansible/playbooks/jenkins-init-container.yml")
  }
}

# Secret for admin credentials
resource "kubernetes_secret_v1" "jenkins_admin" {
  metadata {
    name      = "${var.release_name}-admin"
    namespace = var.kubernetes_namespace
  }

  data = {
    jenkins-admin-user     = var.admin_user
    jenkins-admin-password = var.admin_password != "" ? var.admin_password : "changeme123"
  }

  type = "Opaque"
}

# Jenkins StatefulSet with Ansible Init Container
resource "kubernetes_stateful_set_v1" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace

    labels = {
      app = var.release_name
    }
  }

  spec {
    service_name = var.release_name
    replicas     = 1 # Jenkins master should be single replica

    selector {
      match_labels = {
        app = var.release_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.release_name
        }
        annotations = {
          "checksum/ansible" = sha256(kubernetes_config_map_v1.jenkins_ansible_config.data["jenkins-init.yml"])
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.jenkins.metadata[0].name

        security_context {
          fs_group = 1000 # Jenkins user
        }

        # INIT CONTAINER: Run Ansible to initialize Jenkins
        init_container {
          name  = "ansible-init"
          image = "python:3.11-alpine"

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            set -e
            echo "=== Installing Ansible ==="
            pip install --no-cache-dir ansible
            echo "=== Running Ansible Playbook ==="
            ansible-playbook -c local /ansible/jenkins-init.yml
            EOT
          ]

          env {
            name  = "JENKINS_ADMIN_USER"
            value = var.admin_user
          }

          env {
            name = "JENKINS_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.jenkins_admin.metadata[0].name
                key  = "jenkins-admin-password"
              }
            }
          }

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          volume_mount {
            name       = "ansible-playbook"
            mount_path = "/ansible"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }

        # INIT CONTAINER: Fix permissions for Jenkins user
        init_container {
          name  = "fix-permissions"
          image = "busybox:latest"

          command = ["sh", "-c"]
          args = [
            <<-EOT
            echo "=== Fixing permissions for Jenkins user (UID 1000) ==="
            chown -R 1000:1000 /var/jenkins_home
            chmod -R 755 /var/jenkins_home
            echo "=== Permissions fixed ==="
            ls -la /var/jenkins_home | head -10
            EOT
          ]

          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
          }
        }

        # MAIN CONTAINER: Jenkins
        container {
          name  = "jenkins"
          image = var.jenkins_image

          image_pull_policy = "IfNotPresent"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          port {
            name           = "jnlp"
            container_port = 50000
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          env {
            name  = "JAVA_OPTS"
            value = "${var.java_opts} -Djenkins.install.runSetupWizard=false"
          }

          env {
            name = "JENKINS_ADMIN_ID"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.jenkins_admin.metadata[0].name
                key  = "jenkins-admin-user"
              }
            }
          }

          env {
            name = "JENKINS_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.jenkins_admin.metadata[0].name
                key  = "jenkins-admin-password"
              }
            }
          }

          # Jenkins home directory
          volume_mount {
            name       = "jenkins-home"
            mount_path = "/var/jenkins_home"
          }

          liveness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 120 # Increased for plugin loading
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 5
          }

          readiness_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 90 # Increased for plugin loading
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          # Startup probe for initial boot (helps with slow plugin loading)
          startup_probe {
            http_get {
              path = "/login"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30 # Allow up to 5 minutes for startup
          }
        }

        # VOLUMES
        volume {
          name = "ansible-playbook"
          config_map {
            name = kubernetes_config_map_v1.jenkins_ansible_config.metadata[0].name
          }
        }
      }
    }

    # Persistent Volume Claim Template
    volume_claim_template {
      metadata {
        name = "jenkins-home"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        
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
    kubernetes_secret_v1.jenkins_admin,
    kubernetes_service_v1.jenkins
  ]
}

# Service Account for Jenkins
resource "kubernetes_service_account_v1" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace
  }
}

# RBAC: Role for Jenkins Kubernetes plugin
resource "kubernetes_role_v1" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "pods/log"]
    verbs      = ["create", "delete", "get", "list", "patch", "update", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.jenkins.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.jenkins.metadata[0].name
    namespace = var.kubernetes_namespace
  }
}

# Service
resource "kubernetes_service_v1" "jenkins" {
  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace

    labels = {
      app = var.release_name
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = var.release_name
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    port {
      name        = "jnlp"
      port        = 50000
      target_port = 50000
      protocol    = "TCP"
    }
  }
}

# Ingress
resource "kubernetes_ingress_v1" "jenkins" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = var.release_name
    namespace = var.kubernetes_namespace

    annotations = merge(
      {
        "nginx.ingress.kubernetes.io/proxy-body-size"    = "50m"
        "nginx.ingress.kubernetes.io/proxy-read-timeout" = "600"
        "nginx.ingress.kubernetes.io/proxy-send-timeout" = "600"
      },
      var.ingress_annotations
    )
  }

  spec {
    ingress_class_name = var.ingress_class

    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = var.tls_secret_name
      }
    }

    rule {
      host = var.ingress_host

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.jenkins.metadata[0].name
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service_v1.jenkins,
    kubernetes_stateful_set_v1.jenkins
  ]
}
