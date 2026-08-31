# Contributing

This repository is intentionally small, but changes are treated like changes to a real security-sensitive delivery system.

## Development flow

1. Create a focused branch from `main`.
2. Keep the change narrow enough that its security impact can be reviewed.
3. Update tests and documentation together with the implementation when needed.
4. Open a pull request and complete the security/evidence checklist.
5. Merge only after the repository ruleset and required security checks pass.

Direct pushes to `main` are not the intended development path.

## Local setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --require-hashes -r requirements-dev.lock
pytest
```

Container validation:

```bash
docker build -t secure-api:local .
docker run --rm -p 8000:8000 secure-api:local
```

Terraform validation:

```bash
terraform -chdir=infra init -backend=false
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra validate
terraform -chdir=infra test
```

## Dependency changes

`requirements.in` and `requirements-dev.in` express dependency intent. Lockfiles are generated outputs and must remain hash-locked.

When changing Python dependencies:

1. edit the relevant `.in` file
2. regenerate the lockfile using the same pip-tools process as CI
3. inspect the diff
4. commit input and lockfile together
5. let Dependency Review and lockfile drift validation run on the pull request

Do not manually remove hashes to make an installation pass.

## GitHub Actions

Security-sensitive actions should remain pinned to immutable commit SHAs.

When updating an action:

- identify the intended upstream release
- resolve the release/tag to the exact commit
- review notable behavior or permission changes
- update the comment indicating the human-readable version
- preserve `persist-credentials: false` for checkout unless a reviewed use case requires otherwise
- preserve least-privilege workflow permissions

## Container changes

The runtime is intentionally non-root and distroless.

A container change should not casually reintroduce:

- a root runtime user
- package managers or shells in the final runtime image
- mutable base-image tags in place of digest pins
- dependency installation without `--require-hashes`

If one of those changes is necessary, document the threat-model tradeoff in the pull request.

## Infrastructure changes

Infrastructure changes must pass:

- Terraform formatting
- initialization without backend
- `terraform validate`
- `terraform test`
- HIGH/CRITICAL Trivy configuration scanning

Changes that affect public exposure, IAM, runtime identity, ingress, resource limits or artifact mutability should also update `docs/threat-model.md` and/or `docs/architecture.md`.

## Security claims

A portfolio/reference repository is most credible when claims stay proportional to evidence.

Do not describe a control as implemented unless there is inspectable code, configuration, test or pipeline evidence for it.

Use language such as "planned", "future extension" or "not yet implemented" for roadmap capabilities.

## Vulnerability reporting

See [`SECURITY.md`](SECURITY.md).
