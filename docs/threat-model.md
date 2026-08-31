# Threat Model

## Scope

This threat model covers the software delivery path represented in this repository:

```text
source change -> GitHub review/CI -> container build -> published artifact -> GCP runtime model
```

The sample FastAPI business logic is intentionally minimal. The primary assets are therefore the integrity of the source, dependency set, build process, published container and deployment configuration.

## Security properties we want

1. A change that reaches `main` should have passed the repository's automated security gates.
2. Runtime Python dependencies should correspond to committed hash-locked artifacts.
3. The container runtime should minimize unnecessary privileges and packages.
4. Published artifacts should be identifiable by digest and accompanied by provenance/SBOM evidence.
5. Infrastructure changes should be validated and scanned before merge.
6. The Cloud Run baseline should not be public by default.

## Assets

| Asset | Why it matters |
|---|---|
| Source code | Defines application behavior |
| GitHub workflow definitions | Define the build and security control plane |
| Python lockfiles | Define accepted dependency artifacts |
| Container image | Deployable workload |
| Image digest | Immutable identity of a published workload |
| SBOM | Inventory evidence for the built artifact |
| Build provenance | Evidence linking source/build context to artifact |
| Terraform configuration | Defines the runtime deployment model |
| GitHub token / OIDC identity | Grants publication and attestation capabilities during workflows |

## Adversaries and failure modes

This project considers both malicious activity and accidental security regressions.

Potential actors/failures include:

- contributor introducing vulnerable or malicious code
- accidental secret commit
- compromised or malicious dependency
- stale lockfile causing dependency intent and resolution to diverge
- vulnerable OS or application package in the container
- unsafe container privilege/configuration
- vulnerable HTTP behavior detectable dynamically
- insecure Terraform change
- mutable image/tag substitution
- compromised third-party CI action
- publication of an artifact without inspectable provenance or component inventory

## Threats and controls

| Threat | Control in this repository | Residual risk / limitation |
|---|---|---|
| Malicious or vulnerable source change | tests, CodeQL, pull-request review model | static analysis cannot prove absence of vulnerabilities |
| Secret committed to repository | Gitleaks with full history checkout | detection occurs after a secret may already have been exposed to GitHub; revocation is still required |
| Vulnerable new dependency | Dependency Review fails on high-severity runtime changes | advisory coverage and package metadata are imperfect |
| Dependency substitution / unexpected artifact | pip `--require-hashes` lockfiles | depends on the integrity of the package source and correctness of the committed lock |
| Stale dependency resolution | lockfile drift regeneration in CI | intentional lock updates still require review |
| Vulnerable container packages | Trivy HIGH/CRITICAL gate | `ignore-unfixed` means known findings without fixes are reported differently and require risk judgement |
| Excessive runtime privileges | distroless non-root runtime (`65532`) | kernel/container-runtime security remains outside the image itself |
| Mutable base-image resolution | builder/runtime images pinned by digest | digest trust ultimately depends on registry integrity and image review/update process |
| Basic web misconfiguration | OWASP ZAP baseline | baseline scan is unauthenticated and does not model business workflows |
| Insecure IaC change | Terraform fmt/validate/test + Trivy config scan | cloud-provider policy and organization-level controls are outside this repository |
| Artifact tag moved/reused | GCP Artifact Registry immutable tags; publication exposes image digest | GHCR policy and promotion governance remain separate concerns |
| Build artifact cannot be traced | GitHub build provenance attestation | provenance is evidence, not proof that source itself is safe |
| Unknown artifact components | CycloneDX SBOM + SBOM attestation | SBOM completeness depends on scanner visibility and ecosystem metadata |
| Public Cloud Run exposure | no `allUsers` invoker binding in Terraform baseline | ingress is network-reachable; IAM and surrounding network controls remain important |
| Resource exhaustion | Cloud Run max instances and CPU/memory limits | not a substitute for rate limiting, quotas or abuse protection |
| Compromised CI dependency/action | third-party actions pinned to immutable commit SHAs | upstream action source and chosen commit still need trust/review |

## STRIDE-oriented view

### Spoofing

Primary concern: unauthorized invocation of the deployed service or impersonation of a deployment identity.

Current controls:

- Cloud Run baseline does not configure public `allUsers` invocation.
- publication uses GitHub's short-lived workflow token/OIDC-related permissions rather than a committed long-lived credential.

Not yet implemented:

- application-level identity/authentication.
- workload identity federation for an automated GCP deployment step.

### Tampering

Primary concern: modification of source, dependencies, build inputs, artifacts or IaC.

Current controls:

- pull-request CI gates
- hash-locked Python dependencies
- lockfile drift detection
- digest-pinned container base images
- immutable Artifact Registry tags
- artifact attestations bound to container digest

Residual risk:

- repository branch-protection/ruleset policy is a repository setting and must complement the code-level controls.

### Repudiation

Primary concern: inability to establish which source/build produced an artifact.

Current controls:

- Git commit-based image tag
- image digest
- build provenance attestation
- GitHub workflow logs

Residual risk:

- long-term retention of workflow logs/artifacts depends on platform policy.

### Information disclosure

Primary concern: committed secrets or unintended service exposure.

Current controls:

- Gitleaks
- minimal application surface
- authenticated Cloud Run baseline
- distroless runtime with reduced tooling

Residual risk:

- no dedicated secret-management flow is demonstrated because the sample application currently consumes no application secret.

### Denial of service

Current controls:

- Cloud Run CPU/memory limits
- maximum instance count
- probes and timeout

Not yet implemented:

- rate limiting
- Cloud Armor/WAF policy
- abuse detection
- capacity/SLO engineering

### Elevation of privilege

Current controls:

- non-root distroless runtime
- dedicated Cloud Run service account
- no broad IAM role grants are declared for that runtime account in this repository

Residual risk:

- project/organization inherited IAM policy is outside this repository's visibility.

## Security boundaries intentionally not claimed

The repository does **not** currently claim to provide:

- end-user authentication or authorization
- production secret management
- WAF or API rate limiting
- runtime EDR/SIEM monitoring
- centralized audit-log alerting
- multi-environment promotion policy
- automatic GCP deployment
- SLSA compliance level certification
- compliance certification of any kind
- authenticated DAST/business-logic security testing

These omissions are deliberate to keep claims proportional to implemented evidence.

## Abuse cases for future iterations

High-value next tests include:

1. attempt to introduce a stale/tampered dependency lock and verify CI rejection
2. attempt to add an insecure Terraform public invoker and verify policy rejection
3. attempt to run the container as root and verify a policy test catches the regression
4. verify published image provenance/SBOM using GitHub CLI tooling
5. add an explicit policy-as-code gate for critical Cloud Run invariants
6. add a controlled deployment path using GitHub OIDC -> GCP Workload Identity Federation

## Link to Secure MLOps / AI security

For an ML system, the same threat categories expand to additional artifacts:

- dataset poisoning or substitution
- model artifact tampering
- untrusted model serialization
- training pipeline dependency compromise
- evaluation-result manipulation
- model provenance loss

The architecture in this repository is therefore intended as a software-supply-chain baseline that can later be extended so models and datasets become first-class attested artifacts alongside application containers.
