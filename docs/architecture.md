# Architecture

## Purpose

This document describes the security-relevant architecture of `secure-api-devsecops`. The application is deliberately small; most of the engineering value sits in the controls around how source becomes a deployable artifact.

## System context

```text
+------------------+
|    Developer     |
+--------+---------+
         |
         | push / pull request
         v
+------------------------------+
|          GitHub              |
|                              |
|  source + review boundary    |
+--------------+---------------+
               |
               v
+---------------------------------------------------+
|             Pull-request security gates           |
|                                                   |
|  tests | Gitleaks | lock drift | dependency review|
|  CodeQL | Trivy container | ZAP | Terraform/Trivy|
+--------------------------+------------------------+
                           |
                           | accepted change
                           v
+------------------------------+
|             main             |
+---------------+--------------+
                |
                v
+---------------------------------------------+
|        Container publication workflow       |
|                                             |
|  Docker build -> GHCR image digest          |
|              -> provenance attestation      |
|              -> CycloneDX SBOM              |
|              -> SBOM attestation            |
+--------------------+------------------------+
                     |
                     | immutable artifact identity
                     v
+---------------------------------------------+
|             GCP deployment model            |
|                                             |
| Artifact Registry (immutable tags)          |
|          |                                  |
|          v                                  |
| Cloud Run v2                                |
| - dedicated service account                 |
| - IAM authentication by default             |
| - startup/liveness probes                   |
| - CPU/memory/scaling limits                 |
+---------------------------------------------+
```

## Trust boundaries

### 1. Developer workstation -> GitHub

The repository cannot guarantee the security of a developer workstation. The first enforceable boundary is the GitHub repository and its pull-request workflows.

Relevant controls:

- secret scanning with Gitleaks
- dependency review
- CodeQL
- reproducible dependency intent through committed lockfiles with hashes
- pull-request scans for containers, DAST and IaC

### 2. Source -> build environment

GitHub-hosted runners execute the CI and publication workflows.

Relevant controls:

- workflow permissions are scoped per workflow
- checkout credentials are not persisted where checkout is used
- referenced GitHub Actions are pinned to immutable commit SHAs
- Python dependencies are installed from hash-locked files
- container base images are referenced by digest

### 3. Build -> published artifact

The publication workflow treats the container digest as the artifact identity.

Relevant controls:

- image tag includes the Git commit SHA
- build provenance is attested against the resulting image digest
- a CycloneDX SBOM is generated from the image
- the SBOM is attested against the same digest

A tag is useful for navigation; the digest is the stronger identity for verification and promotion.

### 4. Artifact -> runtime

Terraform models the GCP runtime target.

Relevant controls:

- Artifact Registry Docker repository uses immutable tags
- Cloud Run uses a dedicated service account
- the service is not granted a public `allUsers` invoker binding in this configuration
- resource and scaling limits reduce accidental or abusive resource consumption
- startup and liveness probes provide health signals

## Application runtime

The FastAPI service exposes only two endpoints:

- `/` for service status
- `/health` for health checks

The application adds basic response hardening headers:

- `X-Content-Type-Options: nosniff`
- `Cross-Origin-Resource-Policy: same-origin`

The runtime container is a distroless Debian-based Python image and executes as the non-root UID/GID `65532`.

## Dependency model

`requirements.in` and `requirements-dev.in` express dependency intent.

`requirements.lock` and `requirements-dev.lock` are generated lockfiles containing hashes. CI regenerates the locks and fails when committed files drift from the declared inputs.

This separates two concerns:

- **intent** — what the project asks for
- **resolved evidence** — the exact dependency artifacts accepted by the build

## Infrastructure model

Terraform is intentionally kept small and testable. The repository validates formatting, initialization, configuration validity and Terraform tests on pull requests, then performs a separate Trivy configuration scan for HIGH and CRITICAL findings.

The current infrastructure model is a baseline, not a complete production landing zone. Networking, organization policy, centralized logging, KMS policy, Secret Manager, WAF/rate limiting and environment promotion are intentionally outside the present scope.

## Evidence flow

The project distinguishes between a security control and the evidence produced by that control.

| Control | Evidence |
|---|---|
| Tests | workflow result |
| CodeQL | code-scanning result |
| Trivy container scan | workflow result + generated SBOM |
| OWASP ZAP | JSON/Markdown/HTML reports uploaded as artifacts |
| Terraform validation/tests | workflow result |
| Build publication | container digest |
| Provenance | GitHub artifact attestation |
| SBOM | CycloneDX document + attestation |

This evidence-oriented view is intentional: a secure delivery process should make important claims inspectable after the pipeline has completed.

## Future extension toward Secure MLOps

The same architecture can be extended to ML/AI systems by adding identities and evidence for:

- model artifacts
- training and evaluation datasets
- feature/data pipelines
- model evaluation results
- model signatures and provenance
- deployment-policy checks

The software supply-chain controls in this repository therefore act as a foundation rather than a separate topic from AI security.
