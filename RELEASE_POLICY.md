# Release Policy

Updated: 2026-08-22

## Versioning

Repositories use semantic release tags such as `v1.0.0`. The Open Suite release references exact component/spec versions in a machine-readable manifest. Prerelease tags are unique and are never reused.

## Immutable history

- Main branches are never force-pushed as part of release work.
- A failed or incomplete release tag remains visible for audit.
- Published assets are not silently replaced to conceal a defect.
- A defect in a public stable release is corrected under a new patch version.
- Release notes identify known limitations and the exact source commit.

## Required release evidence

Every stable release requires:

- green repository tests and CI for advertised build targets;
- SHA-256 checksums and a release manifest;
- SBOM and GitHub-supported provenance/attestation for v1.0 and later;
- documented migration/configuration impact;
- install or independent-product execution acceptance appropriate to the repository;
- security review with no unresolved release blocker;
- truthful support and compatibility statements.

The umbrella suite additionally requires all referenced component releases to exist publicly and pass checksum verification before suite publication.

## Approval boundary

Automated gates may produce GO, HOLD, or NO-GO evidence. Production deployment and final risk approval remain explicit human decisions. AI output cannot approve a release or override a deterministic failed gate.

## Security releases

Do not open a public issue for an unpatched vulnerability. Follow each repository's `SECURITY.md`. Once a fix and coordinated disclosure are ready, publish a new immutable patch release and describe affected versions without exposing credentials or private reporter information.

## Support

This open-source project does not promise an SLA. Maintainers publish tested support levels, known limitations, and upgrade notes so users can make informed decisions.

