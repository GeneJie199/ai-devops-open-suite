# AI DevOps Open Suite Roadmap

Updated: 2026-08-23

The roadmap describes product direction. The detailed executable v1.0 gate is maintained in [V1_MASTER_PLAN.md](V1_MASTER_PLAN.md), and current facts are maintained in [PROJECT_STATUS.md](PROJECT_STATUS.md).

## v1.0 GA - trustworthy local-first delivery

### Suite lifecycle

- One-command online install and a genuinely self-contained offline bundle.
- Manifest-driven component selection and integrity verification.
- Tested upgrade from v0.3, versioned rollback, safe uninstall, explicit data purge, restart, doctor, and autostart.
- SBOM, checksums, release manifest, and GitHub-supported provenance.

### DevCycle

- Requirement-first onboarding with complete manual operation when AI is absent.
- Editable AI-assisted plan with assumptions, tests, task order, agents, risk, rollback, and candidate notes.
- Configurable API/CLI providers, secret protection, request preview, adapter lifecycle, and task handoff.
- Humanized Git and evidence-backed acceptance.

### InfraScout

- Useful zero-config Linux discovery across hosts, services, deployments, containers, endpoints, networks, volumes, Nginx, runtimes, databases, and relationships.
- Desired/approved/observed state with structured risk and auditable review decisions.
- Practical PostgreSQL/MySQL metadata drift without reading business rows.

### FleetScope

- Secure Agent onboarding, discovery-based monitoring recommendations, and dense fleet-first triage.
- Native host/application collection with optional standard-format ingestion.
- Resource-group topology, point-in-time snapshots, topology diff, monitoring coverage, and incident impact.
- Unified Change Center and durable alert delivery with storm controls.
- Evidence-backed optional AI explanations with preview and redaction.

### ReleaseGuard

- Candidate, expected changes, preflight, publish observation, Fleet/Infra/DB verification, and final immutable report.
- Metric regression, version consistency, rollback readiness, restart-safe observation, and human-only approval.

### Quality

- Unified design system, Kimi K3 review, responsive browser QA, and basic accessibility.
- Measured scale baseline and honest platform/support matrix.
- Reliability, security, malformed-input, upgrade, and public-asset tests.

Measured v1.0 scale boundary: one FleetScope Center, up to 100 nodes, 8 metrics per node at 60-second intervals, and 3-day retention. Exact Windows/Linux results and resource guidance are in [the scale benchmark](docs/scale-benchmark.md); larger or federated fleets remain post-1.0 work.

## Post-1.0 candidates

These items are intentionally outside the v1.0 gate unless implementation becomes low-risk after the core is complete:

- Enterprise SSO, organization RBAC, multi-tenancy, and policy federation.
- High-availability clustered control planes and multi-region storage.
- Kubernetes operator/control-plane behavior; Kubernetes data may be discovered through future adapters.
- Full distributed tracing backend or a Grafana/Datadog replacement.
- Automated production remediation, deployment, merge, or approval.
- Animated topology time travel beyond point-in-time snapshots and diffs.
- An unrestricted plugin marketplace or remote arbitrary-code collector distribution.
- Guaranteed support for every database, alert channel, AI vendor, and operating system.
- Windows-native infrastructure discovery parity with Linux.
- Windows arm64 artifacts before a complete native test path exists.

## Contribution themes after GA

- Additional read-only collectors and database metadata adapters with fixtures and redaction tests.
- Alert destination adapters sharing the durable delivery contract.
- Agent adapters that preserve worktree, evidence, and interruption semantics.
- Import/export bridges for standard telemetry and incident formats.
- Localization and accessibility improvements.
- Reproducible benchmarks contributed on documented hardware profiles.

Features are accepted based on correctness, safety, maintenance cost, and fit with the local-first evidence model, not feature count.
