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

  validation {
    condition = can(
      regex("@sha256:[0-9a-f]{64}$", var.container_image)
    )

    error_message = "container_image must be pinned to an immutable sha256 digest."
  }
}