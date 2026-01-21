# Jenkins Backup Resources
# This file contains backup-related Kubernetes resources

# Service Account for Backup Operations
resource "kubernetes_service_account_v1" "jenkins_backup" {
  count = var.enable_backup ? 1 : 0

  metadata {
    name      = "${var.release_name}-backup"
    namespace = var.kubernetes_namespace
  }
}

# Role for Backup Operations
resource "kubernetes_role_v1" "jenkins_backup" {
  count = var.enable_backup ? 1 : 0

  metadata {
    name      = "${var.release_name}-backup"
    namespace = var.kubernetes_namespace
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots"]
    verbs      = ["create", "get", "list", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list"]
  }
}

# Role Binding for Backup
resource "kubernetes_role_binding_v1" "jenkins_backup" {
  count = var.enable_backup ? 1 : 0

  metadata {
    name      = "${var.release_name}-backup"
    namespace = var.kubernetes_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.jenkins_backup[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.jenkins_backup[0].metadata[0].name
    namespace = var.kubernetes_namespace
  }
}

# ConfigMap for Backup Script
resource "kubernetes_config_map_v1" "jenkins_backup_script" {
  count = var.enable_backup ? 1 : 0

  metadata {
    name      = "${var.release_name}-backup-script"
    namespace = var.kubernetes_namespace
  }

  data = {
    "backup.sh" = <<-EOT
      #!/bin/bash
      set -e

      echo "=== Jenkins Backup Script ==="
      echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

      BACKUP_NAME="jenkins-backup-$(date +%Y%m%d-%H%M%S)"
      PVC_NAME="${var.release_name}-jenkins-home-${var.release_name}-0"
      NAMESPACE="${var.kubernetes_namespace}"
      SNAPSHOT_CLASS="${var.volume_snapshot_class}"
      RETENTION_DAYS="${var.backup_retention_days}"

      # Create VolumeSnapshot
      echo "Creating VolumeSnapshot: $BACKUP_NAME"
      cat <<EOF | kubectl apply -f -
      apiVersion: snapshot.storage.k8s.io/v1
      kind: VolumeSnapshot
      metadata:
        name: $BACKUP_NAME
        namespace: $NAMESPACE
        labels:
          app: jenkins
          backup: "true"
      spec:
        volumeSnapshotClassName: $SNAPSHOT_CLASS
        source:
          persistentVolumeClaimName: $PVC_NAME
      EOF

      echo "VolumeSnapshot created: $BACKUP_NAME"

      # Wait for snapshot to be ready
      echo "Waiting for snapshot to be ready..."
      kubectl wait --for=jsonpath='{.status.readyToUse}'=true \
        volumesnapshot/$BACKUP_NAME \
        -n $NAMESPACE \
        --timeout=300s

      echo "Snapshot is ready!"

      # Clean up old backups
      echo "Cleaning up backups older than $RETENTION_DAYS days..."
      CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y%m%d)

      kubectl get volumesnapshots -n $NAMESPACE -l backup=true -o json | \
        jq -r ".items[] | select(.metadata.name | test(\"jenkins-backup-\")) | .metadata.name" | \
        while read snapshot; do
          SNAPSHOT_DATE=$(echo $snapshot | grep -oP '\d{8}' || echo "99999999")
          if [ "$SNAPSHOT_DATE" -lt "$CUTOFF_DATE" ]; then
            echo "Deleting old snapshot: $snapshot"
            kubectl delete volumesnapshot $snapshot -n $NAMESPACE
          fi
        done

      echo "=== Backup completed successfully ==="
    EOT
  }
}

# CronJob for Automated Backups
resource "kubernetes_cron_job_v1" "jenkins_backup" {
  count = var.enable_backup && var.volume_snapshot_class != "" ? 1 : 0

  metadata {
    name      = "${var.release_name}-backup"
    namespace = var.kubernetes_namespace

    labels = {
      app  = var.release_name
      type = "backup"
    }
  }

  spec {
    schedule                      = var.backup_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        labels = {
          app  = var.release_name
          type = "backup"
        }
      }

      spec {
        backoff_limit = 3

        template {
          metadata {
            labels = {
              app  = var.release_name
              type = "backup"
            }
          }

          spec {
            service_account_name = kubernetes_service_account_v1.jenkins_backup[0].metadata[0].name
            restart_policy       = "OnFailure"

            container {
              name  = "backup"
              image = "bitnami/kubectl:latest"

              command = ["/bin/bash", "/scripts/backup.sh"]

              env {
                name  = "TZ"
                value = "UTC"
              }

              volume_mount {
                name       = "backup-script"
                mount_path = "/scripts"
                read_only  = true
              }

              resources {
                requests = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
                limits = {
                  cpu    = "500m"
                  memory = "256Mi"
                }
              }
            }

            volume {
              name = "backup-script"
              config_map {
                name         = kubernetes_config_map_v1.jenkins_backup_script[0].metadata[0].name
                default_mode = "0755"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_role_binding_v1.jenkins_backup,
    kubernetes_config_map_v1.jenkins_backup_script
  ]
}

# Optional: ServiceMonitor for Prometheus
resource "kubernetes_manifest" "jenkins_servicemonitor" {
  count = var.enable_prometheus ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = var.release_name
      namespace = var.kubernetes_namespace
      labels = {
        app = var.release_name
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = var.release_name
        }
      }
      endpoints = [
        {
          port     = "http"
          path     = "/prometheus"
          interval = "30s"
        }
      ]
    }
  }

  depends_on = [kubernetes_service_v1.jenkins]
}
