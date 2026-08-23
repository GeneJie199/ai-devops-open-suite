# AI DevOps Open Suite Project Status

Updated: 2026-08-23
Program: v1.0 GA  
State: M1-M7 complete; M8 RC2 gate passed, GA publication active

## Current releases

| Repository | Release | Main commit | CI / release state |
|---|---:|---|---|
| lifecycle-spec | v0.1.1 stable / v1.0.0-rc.2 | `37f13ac2ea4bc7ea5a5316d130ece6537c5dbff5` | RC2 release `32608884772` green |
| DevCycle | v0.3.2 stable / v1.0.0-rc.2 | `2ed6e54328966ca16c1aa6585b3131fb87fdaa83` | RC2 release `32608887394` green |
| InfraScout | v0.3.2 stable / v1.0.0-rc.2 | `b881a03c40fa4f11e9d9ef64f3cf6f5e229cfba6` | RC2 release `32608890134` green |
| FleetScope | v0.3.2 stable / v1.0.0-rc.2 | `f1ebb93172355132c4171a49ed9603771819222e` | RC2 release `32608892328` green |
| ReleaseGuard | v0.3.2 stable / v1.0.0-rc.2 | `8e0d7e8c9feea59e389500713a1c3a0e2bfe17b0` | RC2 release `32608895276` green |
| Open Suite | v0.3.3 stable / v1.0.0-rc.2 | `969890b0d100c4dd0eb2e9d07ff4716b3dec8e08` | RC2 release `32609612650` green; latest main CI active |

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
- M6 unified all four product interfaces on one documented token, icon, focus, state, dialog, responsive, and accessibility baseline. Kimi K3 review, 12 browser viewport combinations, real 10/30-second polling focus checks, mobile command checks, and automated UI-contract tests passed.
- M7 passed all five modules through Windows tests/vet, Linux race tests, Staticcheck, govulncheck, gosec, full-history secret scanning, and targeted parser fuzzing; every final component CI is green.
- M7 exercised disconnect/retry/order/restart/durable-write/SQLite-lock/stale-work/stale-PID/interrupted-upgrade behavior, including real installer lifecycle tests on Windows and isolated Linux paths on host 136.
- FleetScope's measured 100-node workload sustained 3,456,000 samples and 43,200 events with roughly 271 MiB loaded heap on both tested hosts; the documented recommendation deliberately stops at 100 nodes per Center.
- Component and suite release workflows now produce checksums, CycloneDX SBOMs, and GitHub provenance; public artifact validation remains an M8 requirement.
- All six external-user READMEs, support/security/scale documentation, and the one-command Windows/Linux bootstrap path passed local syntax, link, manifest, checksum, and isolated install acceptance.
- M8 RC2 published 71 assets across six immutable prereleases. All 70 attested subjects passed GitHub provenance verification, and every component and suite checksum passed after redownload.
- RC2 public assets passed online bootstrap, complete offline lifecycle, standalone install lifecycle, and public v0.3.3 upgrade/rollback acceptance on Windows amd64 and isolated Linux amd64.
- RC1 exposed two packaging/acceptance blockers. Both were fixed under RC2 without replacing the audit releases: bootstrap now runs `doctor`, and standalone archives now carry a checksum matching their generic executable name.

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

Remaining before GA: immutable RC/GA component assets and public-asset acceptance.

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

Remaining before GA: immutable RC/GA component assets and public-asset acceptance.

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

Remaining before GA: immutable RC/GA component assets and public-asset acceptance.

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

Remaining before GA: immutable RC/GA component assets and public-asset acceptance.

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

- Full offline bundles and supply-chain metadata are implemented and locally verified, but remain development artifacts until component v1 releases exist.
- Final v1 component rebuild, v1 upgrade/rollback acceptance, and public-asset retesting remain pending for RC/GA.
- Native runtime claims remain limited to Windows amd64 and Linux amd64; other built platforms are not promoted by archive availability alone.

## Active work

1. Publish component/spec v1.0.0 releases from the exact RC2-reviewed commits and verify their public assets.
2. Assemble the stable suite manifest from the GA asset digests, then publish Open Suite v1.0.0.
3. Redownload GA assets and repeat public Windows/Linux runtime, UI, Agent, manifest, online, offline, upgrade, rollback, uninstall, and purge smoke tests.
4. Close M8 only after every public release and post-release gate is recorded in the final control handoff.

## Current limitations

- No real macOS runtime acceptance is recorded; macOS is build-tested only.
- Linux arm64 is build-tested only.
- Scale above 100 nodes per FleetScope Center and high availability are not validated v1.0 claims.
- The suite is local/small-team software, not enterprise IAM, RBAC, multi-tenancy, or an automated production remediation platform.
- SBOM, provenance, and full offline bundles passed RC2 public-asset verification but are not promoted as stable until the final v1.0.0 releases pass post-release smoke tests.
- v1.0 GA publication is in progress; until it completes, the latest non-prerelease installation remains Open Suite v0.3.3 with product components v0.3.2.

## Stop conditions

Normal bugs, test failures, design revisions, and CI failures are repaired within the program. Work stops only for the documented hard-stop classes: irreversible deletion of real user data, migrationless breakage of v0.3 data, lowered security defaults, unknown paid cost, unresolved legal risk, suspected supply-chain compromise, or access to unrelated production systems.
