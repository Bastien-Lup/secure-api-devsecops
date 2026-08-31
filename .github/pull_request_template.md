## What changed

<!-- Describe the engineering change and why it is needed. -->

## Security impact

- [ ] No security-relevant behavior changes
- [ ] Security-relevant behavior changes are documented below

<!-- If applicable, describe changes to trust boundaries, permissions, dependencies, container/runtime behavior, IaC or artifact publication. -->

## Evidence

<!-- Link the implementation to concrete repository evidence: tests, workflow jobs, scan output, Terraform tests, SBOM/provenance, etc. -->

## Validation

- [ ] Python tests pass
- [ ] Secret scan passes
- [ ] Lockfile drift passes when dependency inputs are affected
- [ ] Dependency Review passes when dependencies are affected
- [ ] Container scan passes when image inputs are affected
- [ ] DAST/ZAP passes when runtime behavior is affected
- [ ] Terraform validation/tests and IaC scan pass when infrastructure is affected
- [ ] CodeQL has no blocking finding

## Supply-chain checklist

- [ ] Third-party GitHub Actions remain pinned to immutable commit SHAs
- [ ] Container base images remain digest-pinned
- [ ] Dependency lockfiles are regenerated deliberately, not edited by hand
- [ ] Workflow permissions remain least-privilege
- [ ] No secret, token, private key or sensitive personal information is introduced

## Threat model

- [ ] `docs/threat-model.md` still accurately describes the affected control or limitation
- [ ] Threat model updated if this change introduces a new trust boundary or materially changes a security claim

## Documentation

- [ ] README/architecture documentation updated if the public engineering story changes
- [ ] Claims remain proportional to implemented evidence
