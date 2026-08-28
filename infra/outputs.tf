output "artifact_registry_repository" {
  description = "Artifact Registry repository ID"
  value       = google_artifact_registry_repository.secure_api.id
}

output "runtime_service_account" {
  description = "Cloud Run runtime service account"
  value       = google_service_account.runtime.email
}

output "cloud_run_service" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.secure_api.name
}

output "cloud_run_uri" {
  description = "Cloud Run service URI"
  value       = google_cloud_run_v2_service.secure_api.uri
}