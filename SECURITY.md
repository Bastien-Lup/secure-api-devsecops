# Security Policy

## Project status

`secure-api-devsecops` is a security-engineering reference project and portfolio lab. It demonstrates controls around source review, dependency integrity, container hardening, DAST, infrastructure-as-code validation and artifact provenance.

It is not a hosted production service and does not claim compliance certification.

## Reporting a vulnerability

Please do not publish a working exploit, secret or sensitive security detail in a public issue.

For a security issue in this repository, contact the repository owner through the public contact channels linked from the GitHub profile and include:

- affected file/component
- concise description of the issue
- reproduction conditions
- expected security impact
- suggested remediation, if known

If the finding is safe to discuss publicly and contains no exploit/secret material, a normal GitHub issue is acceptable.

## What is considered in scope

Examples:

- security-relevant FastAPI behavior
- CI/CD permission mistakes
- unsafe GitHub Actions usage
- dependency-integrity weaknesses
- container privilege/hardening regressions
- IaC configurations that unintentionally make the modeled service public or overly privileged
- weaknesses in provenance/SBOM generation or artifact identity
- DAST policy regressions

## Out of scope

- attacks against GitHub, Google Cloud, PyPI, GHCR or other third-party services themselves
- social engineering
- denial-of-service testing against third-party infrastructure
- findings that require secrets or credentials not present in this repository

## Security design principles

Changes to the repository should preserve these properties where applicable:

1. **Least privilege** — workflow and runtime permissions should be minimal.
2. **Immutable identity** — prefer commit SHAs and digests over mutable tags for security-sensitive inputs.
3. **Reproducible dependency intent** — Python installs use committed hash-locked requirements.
4. **Evidence generation** — important security claims should produce inspectable CI or artifact evidence.
5. **Fail closed for high-impact findings** — security gates should fail the pull request for configured HIGH/CRITICAL classes rather than silently report only.
6. **Explicit limitations** — documentation must not claim controls that the repository does not implement.

## Dependency and action updates

Security tooling and GitHub Actions are deliberately pinned. Updates should be handled as reviewed changes:

- identify the upstream release/tag
- resolve the exact immutable commit SHA where applicable
- preserve least-privilege workflow permissions
- run all affected CI gates before merge

## Threat model

The repository threat model is maintained in [`docs/threat-model.md`](docs/threat-model.md).
