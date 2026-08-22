# AI DevOps Open Suite Project Status

Updated: 2026-08-23
Program: v1.0 GA  
State: M1-M5 complete; M6 active

## Current releases

| Repository | Release | Main commit | CI / release state |
|---|---:|---|---|
| lifecycle-spec | v0.1.1 / v0.2.0-dev | `2cbd04b8237473f5f296dc947e5970e053909b39` | v0.2.0-dev CI green |
| DevCycle | v0.3.2 / v0.4.0-dev | `11f03ad5c532c4fc0dd9a3d4efcd8dc33d934498` | v0.4.0-dev CI green |
| InfraScout | v0.3.2 / v0.4.0-dev | `f84245c322849edf1f10f00760341fbca455a4a1` | v0.4.0-dev CI green |
| FleetScope | v0.3.2 / v0.4.0-dev | `c51ece279c298f18684a908f656594b3ae87c8df` | v0.4.0-dev CI green |
| ReleaseGuard | v0.3.2 / v0.4.0-dev | `bd340e93ae795d4275c8e96a3ad24d323b499fca` | v0.4.0-dev CI green |
| Open Suite | v0.3.3 | `b909998e8bf57771400b06939b6903e132e9b5f9` | current formal workflows green |

All repositories were clean, on `main`, tracking `origin/main`, and had no ahead/behind divergence at the v1 baseline. The earlier failed Open Suite `v0.3.2` tag remains visible for audit; `v0.3.3` is the corrected immutable release.

## Verified baseline

- Five Go modules pass `go test ./...` and `go vet ./...` on Windows as of 2026-08-22.
- Current public releases contain 39 assets across the six repositories.
- Open Suite v0.3.3 public assets passed checksum/digest and archive-structure verification.
- Windows amd64 passed public-asset install, start, doctor, local Agent, UI readiness, and stop.
- Linux amd64 passed isolated `/tmp` install, runtime, Agent, health, port persistence, stale-PID protection, user-systemd generation, version checks, and cleanup on host 136.
- The 136 acceptance used dynamic loopback ports and isolated paths; it did not access or modify the unrelated SongYueGe environment.
- The v0.4.0-dev lifecycle checkpoint passed manifest-driven online and full-offline installation on Windows amd64 and Linux amd64.
- Public v0.3.3 upgrade/rollback preservation passed on both Windows and Linux; full-data fingerprints covered real product databases, infrastructure state, Fleet identity, release reports, and digest-bound approvals.
- Forced process termination after payload replacement recovered through a durable integrity-checked journal on Windows and Linux.
- DevCycle v0.4.0-dev passed its requirement-first manual/AI workflow, provider and secret controls, five real Agent adapters, evidence gate, responsive browser acceptance, and three-platform CI.
- InfraScout v0.4.0-dev passed native discovery, typed topology, unified infrastructure/database drift review, responsive browser acceptance, and disposable PostgreSQL 16/MySQL 8.4 metadata collection on host 136 using random containers, loopback ports, and `/tmp` paths that were removed afterward.
- FleetScope v0.4.0-dev passed native Windows/macOS/Linux listener and process discovery, topology history/diff, durable multi-channel notification delivery, privacy-scoped evidence/optional AI, one-command local startup, responsive browser acceptance, and an isolated Linux install/runtime plus race test on host 136.
- ReleaseGuard v0.4.0-dev passed versioned expected-change correlation across InfraScout/database/Fleet/topology evidence, cross-stage link validation, deterministic remediation guidance, onboarding/doctor/install lifecycle, responsive browser acceptance, five-target cross-builds, and isolated Linux install/runtime/race acceptance on host 136.

## Capability matrix

### lifecycle-spec

Available now:

- Versioned JSON Schemas and examples for requirements, criteria, tasks, agent sessions, evidence, resources, relationships, snapshots, changes, telemetry, monitoring, incidents, releases, candidates, validation reports, and approvals.
- Offline validator, generated Go/TypeScript types, compatibility tests, redaction tests, and integration documentation.

v1.0 gaps:

- Stable v1 contracts for richer planning, topology snapshots/diffs, database metadata changes, alert delivery, and AI evidence packages. Versioned expected changes and ReleaseGuard correlation evidence are now defined in v0.2.0-dev.
- Explicit v0.1-to-v1 compatibility and migration guidance.

### DevCycle

Available now:

- Local repository import and Git status/branch/log/diff/impact views.
- Requirement, acceptance criterion, task, worktree, verification, evidence, candidate, and development-report flows.
- Real Codex/Kimi/Claude CLI sessions with bounded logs and interruption recovery.
- Optional AI plan preview/apply and AI diff explanation with redaction and strict JSON validation.
- Loopback-only Web UI, SQLite migrations, and deterministic readiness checks.

Delivered on v0.4.0-dev main:

- Requirement-first editable planning covers product understanding, scope, assumptions, questions/defaults, acceptance, tests, tasks, Agent assignment, risk, rollback, and candidate narrative.
- Manual operation remains complete; configurable API providers, OS-keyring/environment credentials, request preview, redaction, and five real Agent adapters are available.
- Humanized Git, raw patch access, durable handoff, canonical evidence, candidate, and development-report paths passed desktop/mobile acceptance.

Remaining before GA: cross-product protocol alignment, final suite installation assets, RC/public-asset acceptance, and final documentation/SBOM/provenance gates.

### InfraScout

Available now:

- Zero-config Linux host/process/listener/systemd discovery.
- Docker containers, images, Compose labels, networks, volumes, Nginx routes, recognized runtimes, exposure, relationships, and monitoring recommendations.
- Approved baseline, deterministic structured diff, noise filtering, severity, auditable classifications, temporary expiry, selected baseline promotion, watch mode, Web UI, and offline report.
- Read-only PostgreSQL/MySQL metadata collection and schema/table/column/index/view/trigger/routine/privilege diff.

Delivered on v0.4.0-dev main:

- First-class Host, Process, Service, Deployment, Container, Database, Endpoint, Volume, Network, Relationship, Observation, Evidence, ChangeEvent, Application, and observed/approved/desired state views.
- PostgreSQL/MySQL metadata v2 includes PK/unique/FK constraints, indexes, views, triggers, routines, roles, and privileges without business-row queries.
- Database and relationship drift share the main decision, fingerprint, blocking-risk, check, Web review, and selective baseline-promotion path.

Remaining before GA: final suite protocol/design convergence, final public assets, and RC acceptance.

### FleetScope

Available now:

- Native Agent with host/application collection, HTTP/TCP/TLS/database probes, bounded concurrent collectors, durable metric/event spools, identity, and secure enrollment.
- Fleet overview, nodes/history, alerts, rules, changes, resource groups, current evidence topology, relationship review, coverage, and database views.
- Native segmented metric/event stores plus optional Prometheus, Influx, and OTLP compatibility inputs.
- Token authentication, optional TLS/mTLS, loopback-safe defaults, collector timeout isolation, spool ordering/recovery, and self-observability tests.

Delivered on v0.4.0-dev main:

- Native OS listener/process discovery and stable safe recommendations work without Prometheus; Prometheus, Influx, and OTLP remain compatibility-only inputs.
- Immutable topology snapshots, point-in-time structural diffs, group/release/incident context, and append-only relationship review are available.
- Durable Webhook, Feishu, WeCom, DingTalk, Slack, Telegram, and SMTP delivery includes grouping, deduplication, suppressions, deployment windows, bounded retry, and manual replay.
- Privacy-scoped immutable evidence packages, explicit redacted AI payload preview/confirmation, assumptions, completeness confidence, and optional provider-neutral explanations are available.
- `fleetctl up`, `fleetctl doctor`, Linux systemd and Windows user installers, native monitoring configuration download, offline icons, and responsive operations workflows are complete.

Remaining before GA: lifecycle v1 contract alignment, final suite installation assets, RC/public-asset acceptance, and final documentation/SBOM/provenance gates.

### ReleaseGuard

Available now:

- Git/commit, command, HTTP, file, JSON, SQL, environment, Compose, drift, Fleet, version, metric-regression, observation-window, and rollback checks.
- DevCycle candidate validation, Git provenance, observation resume, durable run leases/recovery, immutable report, and digest-bound human approval.
- Loopback-safe report UI and protected remote serving/approval write paths.

Delivered on v0.4.0-dev main:

- Versioned Expected Changes are release/version/SHA-256 bound and exactly correlated against InfraScout, database, Fleet, and topology observations; missing, ambiguous, denied, and unexpected evidence blocks deterministically.
- Change declarations link to named checks, metric policies, nodes, and external evidence IDs. Database migrations require database declarations and verification links.
- Candidate, recovery, delivery, verification, changes, observation, immutable report, and human-only approval form one visible evidence flow with prioritized remediation guidance.
- `releaseguard init`, `doctor`, safe `git-ref`, Linux/macOS and Windows installers, complete archives, offline icons, and responsive decision workflows are implemented.
- SQL is single-statement/read-only, malformed Fleet responses are explicit failures, browser mutations are same-origin hardened, and remote serving keeps loopback-safe defaults with an explicit risk warning.

Remaining before GA: suite-wide stable v1 protocol naming, final unified UX/accessibility review, full hardening/scale evidence, SBOM/provenance, RC/public-asset acceptance, and final documentation convergence.

### Open Suite

Available now:

- Checksum-verified online component installation and source-root offline installation.
- Transactional replacement with in-process failure restoration, durable interruption journal, verified next-run recovery, and prior-service restart.
- Unified `suitectl` init/start/stop/restart/status/open/logs/doctor/enable/disable entry point.
- Persistent ports, local Fleet token/identity, Windows Startup, Linux user systemd, macOS LaunchAgent, safe PID verification, and cross-module verification scripts.
- Development manifest `ai-devops.suite-manifest/v1` with exact per-platform component digests and generated dependency-free Bash indexes.
- Platform-specific full offline bundle builder/verifier covering Windows amd64, Linux amd64/arm64, and macOS amd64/arm64.
- Versioned install/backup/uninstall metadata, integrity-checked persistent rollback points, controller-driven upgrade/rollback, data-preserving uninstall, and exact-path-confirmed purge.

v1.0 gaps:

- Full offline bundles are development artifacts until component v1 releases exist; SBOM generation and final public provenance remain pending.
- Final v1 component rebuild, v1 upgrade acceptance, SBOMs, and public-asset retesting remain pending for RC/GA.
- Native runtime claims remain limited to Windows amd64 and Linux amd64; other built platforms are not promoted by archive availability alone.
- Public READMEs/support matrices, scale evidence, provenance, and release gates require v1 completion.

## Active work

1. Deliver M6 unified design-system, onboarding, accessibility, and responsive convergence across all four products.
2. Advance remaining work in dependency order: protocol/design convergence, hardening/scale/security, then complete suite integration and RC.
3. Run Kimi K3 and browser review at every major UI checkpoint.
4. Complete security, reliability, scale, RC, GA, and post-release public smoke gates.

## Current limitations

- No measured scale/HA recommendation has been published.
- No real macOS runtime acceptance is recorded; macOS is build-tested only.
- Linux arm64 is build-tested only.
- The suite is local/small-team software, not enterprise IAM, RBAC, multi-tenancy, or an automated production remediation platform.
- Signing/SBOM/provenance and full offline bundles are not yet part of the current stable release; the new Linux amd64 development bundle has passed a real network-namespace install.
- v1.0 work is in progress; the stable installation remains Open Suite v0.3.3 with product components v0.3.2.

## Stop conditions

Normal bugs, test failures, design revisions, and CI failures are repaired within the program. Work stops only for the documented hard-stop classes: irreversible deletion of real user data, migrationless breakage of v0.3 data, lowered security defaults, unknown paid cost, unresolved legal risk, suspected supply-chain compromise, or access to unrelated production systems.
