data "google_secret_manager_secret_version" "env_file" {
  secret  = "${var.secret_manager_variables}"
  version = "latest"
  project = var.gcp_project_id
}

resource "google_project_service" "run" {
  service = "run.googleapis.com"
}

resource "google_cloud_run_service" "api_biometria_v1" {
  name     = "${var.cloud_run_service_name}-${var.gcp_project_environment}"
  location = var.gcp_project_region

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  template {
    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector" = var.gcp_project_connectors
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
        "autoscaling.knative.dev/minScale"        = "${var.min_instances}"
        "autoscaling.knative.dev/maxScale"        = "${var.max_instances}"
        "revision-id"                             = "${timestamp()}"
      }
    }

    spec {
      containers {
        image = "gcr.io/${var.gcp_project_id}/${var.cloud_run_service_name}-${var.gcp_project_environment}:${var.tag_image}"
        resources {
          limits = {
            cpu    = var.limit_cpu
            memory = var.limit_memory
          }
        }

         # Monta o secret como volume
        volume_mounts {
          name       = "env-secret"
          mount_path = "/secrets/env" # diretório dentro do container
        }

        env {
          name  = "ENV_FILE_PATH"
          value = "/secrets/env/secret" # caminho que o app vai ler
        }

        ports {
          container_port = 8080
        }

        startup_probe {
          http_get {
            path = "/"
            port = 8080
          }
          initial_delay_seconds = 30
          timeout_seconds = 5
          period_seconds = 10
          failure_threshold = 30
        }
      }

      volumes {
        name = "env-secret"

        secret {
          secret_name = var.secret_manager_variables
          items {
            key  = data.google_secret_manager_secret_version.env_file.version
            path = "secret"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run]
}

resource "google_cloud_run_service_iam_member" "noauth" {
  location = google_cloud_run_service.api_biometria_v1.location
  project  = google_cloud_run_service.api_biometria_v1.project
  service  = google_cloud_run_service.api_biometria_v1.name
  role     = "roles/run.invoker"
  member   = "allUsers"

  depends_on = [google_cloud_run_service.api_biometria_v1]
}