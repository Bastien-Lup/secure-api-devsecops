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