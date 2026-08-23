# AI DevOps Open Suite v1.0.0

Released: 2026-08-23

AI DevOps Open Suite v1.0.0 is the first stable release of the complete local-first suite: DevCycle, InfraScout, FleetScope, ReleaseGuard, and lifecycle-spec. Each product works independently and integrates through versioned artifacts and explicit local APIs.

## Highlights

- Requirement-first AI/manual development workflow with real Agent adapters, durable handoff, humanized Git, evidence, and release candidates.
- Native infrastructure and database metadata discovery with approved/observed/desired state, topology, drift review, and release correlation.
- Native fleet monitoring and storage with secure enrollment, topology history, Change Center, durable alert delivery, and optional redacted AI explanations. Prometheus, Influx, and OTLP are compatibility inputs only.
- Deterministic release validation across candidate provenance, expected changes, infrastructure/database/Fleet evidence, observation windows, immutable reports, and digest-bound human approval.
- One-command online install, full platform-specific offline bundles, transactional upgrade, integrity-checked rollback, restart recovery, data-preserving uninstall, and exact-confirmed purge.
- SHA-256 manifests, CycloneDX SBOMs, stable suite manifest, and GitHub build provenance across all releases.

## Verified support

Windows 11 amd64 and Ubuntu 24.04 amd64 passed public v1.0.0 install and runtime acceptance. Linux arm64 and macOS amd64/arm64 artifacts are build-tested only. FleetScope is measured and recommended for up to 100 nodes per Center under the documented 60-second/3-day workload.

See [V1 acceptance](../V1_ACCEPTANCE.md), [support matrix](../SUPPORT_MATRIX.md), [security review](security-review.md), and [scale benchmark](scale-benchmark.md) for the exact claims and limitations.
