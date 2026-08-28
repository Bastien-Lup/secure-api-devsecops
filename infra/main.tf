resource "google_project_service" "artifact_registry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "secure_api" {
  project       = var.project_id
  location      = var.region
  repository_id = "secure-api"
  description   = "Container repository for secure-api"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  depends_on = [
    google_project_service.artifact_registry
  ]
}

resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = "secure-api-runtime"
  display_name = "Secure API Cloud Run runtime"
}

resource "google_cloud_run_v2_service" "secure_api" {
  project  = var.project_id
  name     = "secure-api"
  location = var.region

  deletion_protection = true

  # Network ingress is allowed, but IAM authentication remains enabled.
  # No allUsers / public invoker binding is configured.
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.runtime.email
    timeout         = "30s"

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }

    containers {
      name  = "secure-api"
      image = var.container_image

      ports {
        container_port = 8000
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }

        cpu_idle          = true
        startup_cpu_boost = false
      }

      startup_probe {
        initial_delay_seconds = 0
        timeout_seconds       = 2
        period_seconds        = 3
        failure_threshold     = 10

        http_get {
          path = "/health"
          port = 8000
        }
      }

      liveness_probe {
        initial_delay_seconds = 10
        timeout_seconds       = 2
        period_seconds        = 30
        failure_threshold     = 3

        http_get {
          path = "/health"
          port = 8000
        }
      }
    }
  }

  depends_on = [
    google_project_service.cloud_run
  ]
}