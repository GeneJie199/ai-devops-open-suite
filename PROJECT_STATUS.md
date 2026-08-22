# AI DevOps Open Suite Project Status

Updated: 2026-08-22  
Program: v1.0 GA  
State: M1 complete; M2 active

## Current releases

| Repository | Release | Main commit | CI / release state |
|---|---:|---|---|
| lifecycle-spec | v0.1.1 | `2c9853b7e1959d2ceaaf7289aa5f4a2af0f5f5bd` | current formal workflows green |
| DevCycle | v0.3.2 | `146bced213c2f9c4db8a9d96850822f756feac94` | current formal workflows green |
| InfraScout | v0.3.2 | `7f0765d2e95bce56a69ac486b1924eb018b2e6f1` | current formal workflows green |
| FleetScope | v0.3.2 | `e8c2007fd17ba4a368eb1a81028766bb9db3990a` | current formal workflows green |
| ReleaseGuard | v0.3.2 | `5c299f06179b14cbcaaef8522f7a25005bbb10ea` | current formal workflows green |
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

## Capability matrix

### lifecycle-spec

Available now:

- Versioned JSON Schemas and examples for requirements, criteria, tasks, agent sessions, evidence, resources, relationships, snapshots, changes, telemetry, monitoring, incidents, releases, candidates, validation reports, and approvals.
- Offline validator, generated Go/TypeScript types, compatibility tests, redaction tests, and integration documentation.

v1.0 gaps:

- Stable v1 contracts for richer planning, topology snapshots/diffs, database metadata changes, alert delivery, expected changes, and AI evidence packages.
- Explicit v0.1-to-v1 compatibility and migration guidance.

### DevCycle

Available now:

- Local repository import and Git status/branch/log/diff/impact views.
- Requirement, acceptance criterion, task, worktree, verification, evidence, candidate, and development-report flows.
- Real Codex/Kimi/Claude CLI sessions with bounded logs and interruption recovery.
- Optional AI plan preview/apply and AI diff explanation with redaction and strict JSON validation.
- Loopback-only Web UI, SQLite migrations, and deterministic readiness checks.

v1.0 gaps:

- The planning model does not yet cover the full product brief, test plan, agent assignment, rollback, or candidate narrative.
- AI generation currently invokes three local CLIs; it lacks configurable API-compatible providers and safe secret storage.
- Agent adapters need Gemini CLI, OpenCode, and custom definitions plus stronger handoff UX.
- Humanized Git and evidence types need a complete beginner-facing acceptance path.

### InfraScout

Available now:

- Zero-config Linux host/process/listener/systemd discovery.
- Docker containers, images, Compose labels, networks, volumes, Nginx routes, recognized runtimes, exposure, relationships, and monitoring recommendations.
- Approved baseline, deterministic structured diff, noise filtering, severity, auditable classifications, temporary expiry, selected baseline promotion, watch mode, Web UI, and offline report.
- Read-only PostgreSQL/MySQL metadata collection and schema/table/column/index/view/trigger/routine/privilege diff.

v1.0 gaps:

- The generic resource model and protocol mapping require consolidation and stable v1 serialization.
- Database metadata lacks complete primary/unique/foreign-key and user/role detail and is not yet integrated into the main review/evidence path.
- Desired-state and release-correlation semantics need completion and browser onboarding needs simplification.

### FleetScope

Available now:

- Native Agent with host/application collection, HTTP/TCP/TLS/database probes, bounded concurrent collectors, durable metric/event spools, identity, and secure enrollment.
- Fleet overview, nodes/history, alerts, rules, changes, resource groups, current evidence topology, relationship review, coverage, and database views.
- Native segmented metric/event stores plus optional Prometheus, Influx, and OTLP compatibility inputs.
- Token authentication, optional TLS/mTLS, loopback-safe defaults, collector timeout isolation, spool ordering/recovery, and self-observability tests.

v1.0 gaps:

- Topology is currently derived from retained reports but lacks explicit topology snapshots, point-in-time retrieval, and topology diff.
- Change Center does not yet aggregate database/topology change documents into one stable public contract.
- Alert delivery is basic webhook notification and needs durable delivery, dedupe/grouping/suppression/windows/retries and maintained channels.
- Monitoring onboarding and AI evidence-package/privacy flows are incomplete.

### ReleaseGuard

Available now:

- Git/commit, command, HTTP, file, JSON, SQL, environment, Compose, drift, Fleet, version, metric-regression, observation-window, and rollback checks.
- DevCycle candidate validation, Git provenance, observation resume, durable run leases/recovery, immutable report, and digest-bound human approval.
- Loopback-safe report UI and protected remote serving/approval write paths.

v1.0 gaps:

- Expected infrastructure/database/topology change contracts need first-class validation and correlation.
- Cross-product release reporting needs a single stable v1 evidence chain and clearer failure remediation.
- Upgrade, scale, fuzz, security, and public-asset acceptance remain to be completed.

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

1. Deliver the M2 DevCycle requirement-first, provider-neutral, evidence-backed workflow.
2. Advance product work in dependency order: protocol, DevCycle/InfraScout, FleetScope, ReleaseGuard, then complete suite integration.
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
