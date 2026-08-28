variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP deployment region"
  type        = string
  default     = "europe-west1"
}

variable "container_image" {
  description = "Immutable container image reference deployed to Cloud Run"
  type        = string

