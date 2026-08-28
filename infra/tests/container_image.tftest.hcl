mock_provider "google" {}

run "accept_digest_pinned_image" {
  command = plan

  variables {
    project_id = "secure-api-test"
    region     = "europe-west1"

    container_image = "europe-west1-docker.pkg.dev/secure-api-test/secure-api/secure-api@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
}

run "reject_mutable_tag" {
  command = plan

  variables {
    project_id = "secure-api-test"
    region     = "europe-west1"

    container_image = "europe-west1-docker.pkg.dev/secure-api-test/secure-api/secure-api:latest"
  }

  expect_failures = [
    var.container_image
  ]
}
