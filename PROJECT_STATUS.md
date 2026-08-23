# AI DevOps Open Suite Project Status

Updated: 2026-08-23
Program: v1.0 GA  
State: v1.0 GA published; M0-M8 and post-release smoke acceptance complete

## Current releases

| Repository | Release | Main commit | CI / release state |
|---|---:|---|---|
| lifecycle-spec | v1.0.0 | `37f13ac2ea4bc7ea5a5316d130ece6537c5dbff5` | CI `32606515988`; release `32611930244` green |
| DevCycle | v1.0.0 | `2ed6e54328966ca16c1aa6585b3131fb87fdaa83` | CI `32608756530`; release `32611935082` green |
| InfraScout | v1.0.0 | `b881a03c40fa4f11e9d9ef64f3cf6f5e229cfba6` | CI `32608761040`; release `32611939162` green |
| FleetScope | v1.0.0 | `f1ebb93172355132c4171a49ed9603771819222e` | CI `32608763602`; release `32611943459` green |
| ReleaseGuard | v1.0.0 | `8e0d7e8c9feea59e389500713a1c3a0e2bfe17b0` | CI `32608767066`; release `32611949369` green |
| Open Suite | v1.0.0 | GA tag `076be4e153e64c919870950fe7b67b9ff38e5ab9` | manifest CI `32612512050`; release `32612562754` green |

All repositories are on `main`, track `origin/main`, and were clean and synchronized after GA acceptance. The earlier RC1/RC2 releases and failed historical Open Suite `v0.3.2` tag remain visible for audit and were not rewritten.

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
- M6 unified all four product interfaces on one documented token, icon, focus, state, dialog, responsive, and accessibility baseline. Kimi K3 review, 12 browser viewport combinations, real 10/30-second polling focus checks, mobile command checks, and automated UI-contract tests passed.
- M7 passed all five modules through Windows tests/vet, Linux race tests, Staticcheck, govulncheck, gosec, full-history secret scanning, and targeted parser fuzzing; every final component CI is green.
- M7 exercised disconnect/retry/order/restart/durable-write/SQLite-lock/stale-work/stale-PID/interrupted-upgrade behavior, including real installer lifecycle tests on Windows and isolated Linux paths on host 136.
- FleetScope's measured 100-node workload sustained 3,456,000 samples and 43,200 events with roughly 271 MiB loaded heap on both tested hosts; the documented recommendation deliberately stops at 100 nodes per Center.
- Component and suite release workflows produce checksums, CycloneDX SBOMs, and GitHub provenance; every GA subject was redownloaded and verified.
- All six external-user READMEs, support/security/scale documentation, and the one-command Windows/Linux bootstrap path passed local syntax, link, manifest, checksum, and isolated install acceptance.
- M8 RC2 published 71 assets across six immutable prereleases. All 70 attested subjects passed GitHub provenance verification, and every component and suite checksum passed after redownload.
- RC2 public assets passed online bootstrap, complete offline lifecycle, standalone install lifecycle, and public v0.3.3 upgrade/rollback acceptance on Windows amd64 and isolated Linux amd64.
- RC1 exposed two packaging/acceptance blockers. Both were fixed under RC2 without replacing the audit releases: bootstrap now runs `doctor`, and standalone archives now carry a checksum matching their generic executable name.
- Six stable v1.0.0 releases contain 71 public assets. All 64 checksummed artifacts passed their published SHA-256 manifests and all 70 attested subjects passed GitHub provenance verification.
- GA post-release smoke passed the public README bootstrap, full offline lifecycle, UI/Agent runtime, and public v0.3.3 upgrade/rollback paths on Windows amd64 and Linux amd64. Linux also passed a real no-network namespace install and all four standalone product installer lifecycles.

## Capability matrix

### lifecycle-spec

Available now:

- Versioned JSON Schemas and examples for requirements, criteria, tasks, agent sessions, evidence, resources, relationships, snapshots, changes, telemetry, monitoring, incidents, releases, candidates, validation reports, and approvals.
- Offline validator, generated Go/TypeScript types, compatibility tests, redaction tests, and integration documentation.

GA status: the v1.0.0 protocol package preserves the published v0.1 contracts and adds strict Expected Changes and release-correlation contracts, synchronized types, compatibility fixtures, redaction, and offline validation.

### DevCycle

Available now:

- Local repository import and Git status/branch/log/diff/impact views.
- Requirement, acceptance criterion, task, worktree, verification, evidence, candidate, and development-report flows.
- Real Codex/Kimi/Claude CLI sessions with bounded logs and interruption recovery.
- Optional AI plan preview/apply and AI diff explanation with redaction and strict JSON validation.
- Loopback-only Web UI, SQLite migrations, and deterministic readiness checks.

Delivered in v1.0.0:

- Requirement-first editable planning covers product understanding, scope, assumptions, questions/defaults, acceptance, tests, tasks, Agent assignment, risk, rollback, and candidate narrative.
- Manual operation remains complete; configurable API providers, OS-keyring/environment credentials, request preview, redaction, and five real Agent adapters are available.
- Humanized Git, raw patch access, durable handoff, canonical evidence, candidate, and development-report paths passed desktop/mobile acceptance.

GA status: standalone and suite-contained assets passed public checksum, provenance, runtime, upgrade, and recovery gates.

### InfraScout

Available now:

- Zero-config Linux host/process/listener/systemd discovery.
- Docker containers, images, Compose labels, networks, volumes, Nginx routes, recognized runtimes, exposure, relationships, and monitoring recommendations.
- Approved baseline, deterministic structured diff, noise filtering, severity, auditable classifications, temporary expiry, selected baseline promotion, watch mode, Web UI, and offline report.
- Read-only PostgreSQL/MySQL metadata collection and schema/table/column/index/view/trigger/routine/privilege diff.

Delivered in v1.0.0:

- First-class Host, Process, Service, Deployment, Container, Database, Endpoint, Volume, Network, Relationship, Observation, Evidence, ChangeEvent, Application, and observed/approved/desired state views.
- PostgreSQL/MySQL metadata v2 includes PK/unique/FK constraints, indexes, views, triggers, routines, roles, and privileges without business-row queries.
- Database and relationship drift share the main decision, fingerprint, blocking-risk, check, Web review, and selective baseline-promotion path.

GA status: standalone and suite-contained assets passed public checksum, provenance, runtime, upgrade, and recovery gates.

### FleetScope

Available now:

- Native Agent with host/application collection, HTTP/TCP/TLS/database probes, bounded concurrent collectors, durable metric/event spools, identity, and secure enrollment.
- Fleet overview, nodes/history, alerts, rules, changes, resource groups, current evidence topology, relationship review, coverage, and database views.
- Native segmented metric/event stores plus optional Prometheus, Influx, and OTLP compatibility inputs.
- Token authentication, optional TLS/mTLS, loopback-safe defaults, collector timeout isolation, spool ordering/recovery, and self-observability tests.

Delivered in v1.0.0:

- Native OS listener/process discovery and stable safe recommendations work without Prometheus; Prometheus, Influx, and OTLP remain compatibility-only inputs.
- Immutable topology snapshots, point-in-time structural diffs, group/release/incident context, and append-only relationship review are available.
- Durable Webhook, Feishu, WeCom, DingTalk, Slack, Telegram, and SMTP delivery includes grouping, deduplication, suppressions, deployment windows, bounded retry, and manual replay.
- Privacy-scoped immutable evidence packages, explicit redacted AI payload preview/confirmation, assumptions, completeness confidence, and optional provider-neutral explanations are available.
- `fleetctl up`, `fleetctl doctor`, Linux systemd and Windows user installers, native monitoring configuration download, offline icons, and responsive operations workflows are complete.

GA status: standalone and suite-contained assets passed public checksum, provenance, runtime, Agent, upgrade, and recovery gates.

### ReleaseGuard

Available now:

- Git/commit, command, HTTP, file, JSON, SQL, environment, Compose, drift, Fleet, version, metric-regression, observation-window, and rollback checks.
- DevCycle candidate validation, Git provenance, observation resume, durable run leases/recovery, immutable report, and digest-bound human approval.
- Loopback-safe report UI and protected remote serving/approval write paths.

Delivered in v1.0.0:

- Versioned Expected Changes are release/version/SHA-256 bound and exactly correlated against InfraScout, database, Fleet, and topology observations; missing, ambiguous, denied, and unexpected evidence blocks deterministically.
- Change declarations link to named checks, metric policies, nodes, and external evidence IDs. Database migrations require database declarations and verification links.
- Candidate, recovery, delivery, verification, changes, observation, immutable report, and human-only approval form one visible evidence flow with prioritized remediation guidance.
- `releaseguard init`, `doctor`, safe `git-ref`, Linux/macOS and Windows installers, complete archives, offline icons, and responsive decision workflows are implemented.
- SQL is single-statement/read-only, malformed Fleet responses are explicit failures, browser mutations are same-origin hardened, and remote serving keeps loopback-safe defaults with an explicit risk warning.

GA status: standalone and suite-contained assets passed public checksum, provenance, runtime, upgrade, and recovery gates.

### Open Suite

Available now:

- Checksum-verified online component installation and source-root offline installation.
- Transactional replacement with in-process failure restoration, durable interruption journal, verified next-run recovery, and prior-service restart.
- Unified `suitectl` init/start/stop/restart/status/open/logs/doctor/enable/disable entry point.
- Persistent ports, local Fleet token/identity, Windows Startup, Linux user systemd, macOS LaunchAgent, safe PID verification, and cross-module verification scripts.
- Stable manifest `ai-devops.suite-manifest/v1` with exact per-platform component digests and generated dependency-free Bash indexes.
- Platform-specific full offline bundle builder/verifier covering Windows amd64, Linux amd64/arm64, and macOS amd64/arm64.
- Versioned install/backup/uninstall metadata, integrity-checked persistent rollback points, controller-driven upgrade/rollback, data-preserving uninstall, and exact-path-confirmed purge.

GA status: the stable suite, online aliases, five complete offline bundles, aggregate SBOM, checksums, and provenance are public. Native runtime claims remain limited to Windows amd64 and Linux amd64; other built platforms are not promoted by archive availability alone.

## Completed GA gate

The component/spec releases, stable suite manifest, Open Suite release, public-asset redownload, Windows/Linux post-release smoke, final public documentation, and control handoff all completed. No known v1.0 release blocker remains.

## Current limitations

- No real macOS runtime acceptance is recorded; macOS is build-tested only.
- Linux arm64 is build-tested only.
- Scale above 100 nodes per FleetScope Center and high availability are not validated v1.0 claims.
- The suite is local/small-team software, not enterprise IAM, RBAC, multi-tenancy, or an automated production remediation platform.
- Native runtime acceptance is recorded only for Windows 11 amd64 and Ubuntu 24.04 amd64; artifact availability is not a runtime support claim.
- v1.0.0 is the current stable GitHub release and the default `releases/latest` bootstrap target.

## Stop conditions

Normal bugs, test failures, design revisions, and CI failures are repaired within the program. Work stops only for the documented hard-stop classes: irreversible deletion of real user data, migrationless breakage of v0.3 data, lowered security defaults, unknown paid cost, unresolved legal risk, suspected supply-chain compromise, or access to unrelated production systems.
