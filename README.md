# Secure API DevSecOps

[![CI](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/ci.yml/badge.svg)](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/ci.yml)
[![CodeQL](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/codeql.yml/badge.svg)](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/codeql.yml)
[![Container Security](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/container-security.yml/badge.svg)](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/container-security.yml)
[![DAST](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/dast.yml/badge.svg)](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/dast.yml)
[![IaC](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/iac.yml/badge.svg)](https://github.com/bastien-ladra/secure-api-devsecops/actions/workflows/iac.yml)

**Portfolio :** [bastien-ladra.github.io/portfolio-bastien-ladra](https://bastien-ladra.github.io/portfolio-bastien-ladra/) · **Étude de cas FR :** [Secure API DevSecOps](https://bastien-ladra.github.io/portfolio-bastien-ladra/case-study-secure-api-fr.html) · **Case study EN :** [Secure API DevSecOps](https://bastien-ladra.github.io/portfolio-bastien-ladra/case-study-secure-api.html)

## Résumé recruteur

Ce dépôt est un projet de référence **DevSecOps / software supply chain / cloud security** construit autour d'une API FastAPI volontairement simple afin de rendre les contrôles de livraison faciles à inspecter.

Il démontre concrètement :

- **CI et sécurité du code** : tests Python, Gitleaks, Dependency Review et CodeQL ;
- **sécurité conteneur** : build multi-stage, runtime distroless non-root et scan Trivy HIGH/CRITICAL ;
- **preuves supply-chain** : SBOM CycloneDX, provenance de build et attestation SBOM ;
- **DAST et IaC** : OWASP ZAP baseline, Terraform validate/test et scan de configuration Trivy ;
- **cible cloud GCP** : Artifact Registry à tags immuables, Cloud Run avec identité dédiée et service non public par défaut.

Le projet ne cherche pas à empiler des outils : il montre comment les contrôles s'enchaînent de la pull request jusqu'à l'artefact publiable, avec leurs **preuves et limites explicites**.

> Pour une lecture rapide orientée recrutement, l'étude de cas française ci-dessus synthétise l'architecture, les résultats et les limites. La suite de ce README conserve le niveau de détail technique nécessaire à une revue d'ingénierie.

---

A compact reference project for building and validating a secure software delivery path around a FastAPI service.

The goal is not to demonstrate one scanner. It is to show how security controls compose across **source code, dependencies, containers, infrastructure and artifact publication**.

## Security objectives

This repository is designed around four practical objectives:

1. **Prevent unreviewed or stale dependencies from entering the build.**
2. **Reduce trust in mutable build inputs and runtime images.**
3. **Generate evidence that can be inspected after the build.**
4. **Keep deployment infrastructure explicit and testable as code.**

## Delivery architecture

```text
Developer change
      |
      v
Pull Request
      |
      +--> Python tests
      +--> Secret scanning
      +--> Lockfile drift check
      +--> Dependency review
      +--> CodeQL
      +--> Container scan + SBOM
      +--> OWASP ZAP baseline
      +--> Terraform validate/test + IaC scan
      |
      v
     main
      |
      v
Container build
      |
      +--> GHCR image by commit SHA
      +--> Build provenance attestation
      +--> CycloneDX SBOM
      +--> SBOM attestation
      |
      v
GCP deployment target
Artifact Registry -> Cloud Run
```

See [`docs/architecture.md`](docs/architecture.md) for the system view and [`docs/threat-model.md`](docs/threat-model.md) for the threat model.

## Controls implemented

| Area | Control | Evidence in repository |
|---|---|---|
| Source | Python tests | `.github/workflows/ci.yml` |
| Secrets | Gitleaks scan | `.github/workflows/ci.yml` |
| Dependencies | Hash-locked Python dependencies | `requirements.lock`, `requirements-dev.lock` |
| Dependencies | Lockfile drift detection | `.github/workflows/ci.yml` |
| Dependencies | Dependency Review gate | `.github/workflows/dependency-review.yml` |
| SAST | CodeQL with `security-extended` | `.github/workflows/codeql.yml` |
| Container | Multi-stage build | `Dockerfile` |
| Container | Distroless non-root runtime | `Dockerfile` |
| Container | Trivy HIGH/CRITICAL gate | `.github/workflows/container-security.yml` |
| Supply chain | CycloneDX SBOM | container/publish workflows |
| Supply chain | Build provenance attestation | `.github/workflows/publish.yml` |
| Supply chain | SBOM attestation | `.github/workflows/publish.yml` |
| DAST | OWASP ZAP baseline | `.github/workflows/dast.yml` |
| IaC | Terraform fmt/validate/test | `.github/workflows/iac.yml` |
| IaC | Trivy configuration scan | `.github/workflows/iac.yml` |
| Cloud | Immutable Artifact Registry tags | `infra/main.tf` |
| Cloud | Dedicated Cloud Run service account | `infra/main.tf` |
| Cloud | No public `allUsers` invoker binding | `infra/main.tf` |
| Runtime | Startup and liveness probes | `infra/main.tf` |
| Application | Basic HTTP security headers | `app/main.py` |

## Application

The service intentionally stays small so the delivery controls remain easy to inspect.

Endpoints:

- `GET /` — service status
- `GET /health` — health endpoint used by container and Cloud Run probes

Security headers currently added by middleware:

- `X-Content-Type-Options: nosniff`
- `Cross-Origin-Resource-Policy: same-origin`

## Local development

Requirements:

- Python 3.13
- Docker
- Terraform 1.15.x for infrastructure validation

Create a virtual environment and install the development lockfile:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --require-hashes -r requirements-dev.lock
```

Run the tests:

```bash
pytest
```

Run the API:

```bash
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Build the hardened container:

```bash
docker build -t secure-api:local .
docker run --rm -p 8000:8000 secure-api:local
```

## Infrastructure

Terraform provisions the baseline GCP deployment target:

- Artifact Registry Docker repository with immutable tags
- dedicated runtime service account
- Cloud Run v2 service
- bounded CPU/memory and scaling
- startup and liveness probes
- IAM-authenticated service by default

The deployment configuration expects an image reference through `var.container_image`; production promotion should use an immutable image digest.

Validate locally:

```bash
terraform -chdir=infra init -backend=false
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra validate
terraform -chdir=infra test
```

## Supply-chain evidence

On publication, the workflow pushes an image tagged from the Git commit and produces:

- an image digest
- GitHub build provenance attestation
- CycloneDX SBOM
- SBOM attestation linked to the same image digest

This makes the published artifact inspectable beyond a mutable tag alone.

## Threat model and limitations

This repository demonstrates preventive and detective controls, but it is **not presented as a production-complete platform**.

Important boundaries include:

- no application authentication/authorization layer yet
- no WAF/rate-limiting policy in this repository
- no runtime SIEM/alerting integration
- no secret-manager integration because the sample service currently requires no application secret
- no automated promotion from GHCR to GCP in the current baseline
- DAST is a baseline scan against the local container, not an authenticated business-flow test

Those boundaries are documented explicitly in [`docs/threat-model.md`](docs/threat-model.md).

## Why this project exists

The project is an engineering lab for a broader question: **how can delivery pipelines produce evidence that a deployed workload is the result of reviewed source, controlled dependencies, hardened build inputs and verifiable artifacts?**

That same question extends naturally toward Secure MLOps and AI systems, where software provenance must eventually include models, datasets and pipeline metadata as well.

## Repository map

```text
.
├── app/                     # FastAPI service
├── tests/                   # application tests
├── infra/                   # Terraform GCP baseline and tests
├── .zap/                    # ZAP baseline policy
├── .github/workflows/       # CI, SAST, DAST, IaC, container and publication controls
├── docs/                    # architecture and threat model
├── Dockerfile               # hardened multi-stage container
├── requirements.in          # runtime dependency intent
├── requirements.lock        # runtime hash lock
├── requirements-dev.in      # development dependency intent
└── requirements-dev.lock    # development hash lock
```

## License / usage

This repository is primarily a security-engineering reference and portfolio project. Review the controls and adapt them to the threat model, platform and compliance requirements of your own environment before production use.
