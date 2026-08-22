# v0.4.0-dev Product Delivery Checkpoint

Date: 2026-08-22
Scope: M1-M3 development checkpoint, not a public release

## Implemented

- `ai-devops.suite-manifest/v1` pins repository, tag, component version, platform asset, target name, and SHA-256.
- Generated per-platform install indexes let Bash consume the same manifest without requiring Python or `jq` on the target host.
- The full offline builder packages all five executables, the lifecycle protocol archive, installer/controller, manifest, file digests, documentation, and examples.
- The offline verifier rejects unsafe archive paths, links, undeclared files, stale indexes, non-executable Unix installers, and component/protocol digest mismatches.
- `suitectl` supports version, upgrade, rollback, uninstall, and purge. Upgrade backups are persistent and integrity checked before rollback.
- A durable install transaction journal is written before services stop or payloads change. The next installer invocation verifies the backup, restores every managed file, records `last-install-recovery.json`, restarts a previously running suite, and then safely retries the requested install.
- Online downloads have bounded retries and timeouts. Bash retains partial downloads and resumes them on retry; offline mode never enters this path.
- Uninstall preserves data/config/logs/protocols/backups. Purge requires the exact canonical suite path and refuses roots and links/reparse points.
- Release workflow refuses an existing Release, requires tag/manifest agreement, builds all offline platforms, verifies them, and creates GitHub build provenance.

## Windows amd64 acceptance

- Full offline install: pass.
- Four services and local Fleet Agent on dynamic loopback ports: pass.
- Doctor: pass.
- Controller-driven upgrade and explicit rollback: pass.
- User data marker across rollback and uninstall: pass.
- Default uninstall leaves zero managed binaries and preserves data: pass.
- Exact-path-confirmed purge: pass.
- Missing offline asset with network fallback disabled: correctly rejected.
- Tampered backup binary: correctly rejected before any rollback mutation.
- A child Windows PowerShell process was forcibly terminated after payload replacement. The next invocation restored the prior binary from the integrity-checked journal before continuing.
- Windows PowerShell 5.1 compatibility: pass, including install, service runtime, Doctor, rollback, uninstall, and purge.
- Persisted ports were unchanged when an upgrade process inherited different ambient port variables.
- DevCycle requirement DB, Fleet identity/registration, ReleaseGuard report, and digest-bound approval retained identical full-data fingerprints through upgrade and rollback.
- Manifest-driven online install, five downloads, Doctor, and purge on dynamic ports: pass.

The current development installer was also applied to a clean installation created from the public Open Suite v0.3.3 ZIP. Four product data markers, the Fleet token, and persisted port configuration survived upgrade and rollback. Rollback restored `suite-version` to `0.3.3`.

## Linux amd64 acceptance

Host 136 was used only in random `/tmp/ai-devops-v1-accept.*` paths and dynamic loopback ports. No SongYueGe path, service, container, or data was accessed or modified.

- Full offline install, start, Agent, four service endpoints, Doctor, stop: pass.
- Controller-driven upgrade, rollback, uninstall-preserve, reinstall, purge: pass.
- Forced post-payload commit failure restored the prior binary immediately: pass.
- A real installer process was killed after payload replacement; the persisted journal restored the prior installation on the next invocation: pass.
- Tampered persistent backup was rejected: pass.
- Missing local asset did not fall back to the network: pass.
- A separate root network namespace with no network interfaces ran only installer/controller initialization and wrote an offline five-component install state: pass.
- All remote acceptance directories were removed after the test.
- DevCycle requirement DB, InfraScout baseline/inventory, Fleet identity/registration, ReleaseGuard report, and digest-bound approval retained identical full-data fingerprints through upgrade and rollback.
- Manifest-driven online install, five downloads, Doctor, and purge on dynamic ports: pass.
- The public v0.3.3 launcher upgraded to this checkpoint and rolled back to `suite-version` 0.3.3 while preserving four product markers, Fleet token, and ports: pass.

InfraScout reported Docker socket permission as a warning for the unprivileged user; this was expected and avoided reading unrelated containers.

## Bundle structure verification

All five platform archives passed the offline verifier. These local development digests are evidence only and are not public release claims:

| Platform | Archive size | SHA-256 |
|---|---:|---|
| Windows amd64 | 22,559,163 | `85032241d0b4248a3d72ec16bd043e7434c69bd39dbec41c1144990501339bdc` |
| Linux amd64 | 22,082,104 | `91f8219e19f4bce49bcec09b4cfe0c86c12479dace07093f9d5e0ad1a41deb77` |
| Linux arm64 | 20,199,231 | `3e47d291d4d79eb2e07a14c8579de0828eff8d57fa561e426a88091e7f12e92e` |
| macOS amd64 | 22,355,856 | `77da4eaa82bd26fbda949f0739be2d378c3ec9a4e4bb11bc13452df56d8d0362` |
| macOS arm64 | 20,920,130 | `182c0efce75930f555976a316a291d5a4fe7db7ebf1ac43ae3156e368b2fc9c6` |

## M1 result

M1 is complete. Its repeatable acceptance entry points are `accept-offline-windows.ps1`, `accept-offline-linux.sh`, `accept-online-windows.ps1`, `accept-online-linux.sh`, `accept-upgrade-from-v033-linux.sh`, and the network-namespace harness.

The archives in this document remain development evidence, not public v1 releases. They must be rebuilt from v1 component releases and receive component SBOMs before RC. macOS and Linux arm64 remain build-tested only until native runtime evidence exists.

## M2 DevCycle delivery checkpoint

Repository: `GeneJie199/ai-dev-cycle-manager`

- Commit: `11f03ad5c532c4fc0dd9a3d4efcd8dc33d934498` (`feat: deliver complete AI development lifecycle`).
- GitHub CI: <https://github.com/GeneJie199/ai-dev-cycle-manager/actions/runs/32582766983>.
- Windows, macOS, and Linux tests, vet, build, and CLI smoke: pass.
- Linux formatting, race detector, Staticcheck, and reachable Govulncheck: pass.
- Local Govulncheck initially identified five Go 1.26.5 standard-library vulnerabilities. The minimum toolchain was raised to Go 1.26.6 and the repeated scan returned `No vulnerabilities found`.

### Product surface

- Natural-language requirement capture and a five-stage intent, acceptance, execution, verification, and release workflow.
- Durable editable `devcycle.planning-document/v1` documents with scope, assumptions, blocking questions/defaults, criteria, test cases, strategy, ordered tasks/dependencies/adapters/deliverables, risks, rollback concerns, candidate notes, provenance, optimistic revisions, and atomic application.
- Provider-neutral AI planning through local Kimi/Codex/Claude CLIs or configurable OpenAI-compatible, Anthropic, Gemini, local OpenAI/Ollama, and custom OpenAI APIs.
- API request preview, prompt and error redaction, OS-keyring or environment-backed credentials, HTTPS enforcement for credentialed remote providers, redirect refusal, response bounds, and connection tests.
- Codex, Claude Code, Gemini CLI, Kimi Code, and OpenCode execution adapters plus constrained custom executable/argv adapters with no Shell or adapter environment injection.
- Durable cross-Agent task handoffs, acceptance, work completed/remaining, risks, validation, and changed-file context.
- Canonical code, commit, test, screenshot, command, HTTP-response, artifact, and human-confirmation Evidence with legacy alias normalization.
- Humanized Git classification, five impact surfaces including security, risk reasons, suggested validation, structured files, and a verified real raw patch view.
- Complete AI/Agent/repository settings, global activity center, offline Lucide assets, and revised end-user/configuration/operations/protocol documentation.

### UX acceptance

- Kimi K3 performed two independent read-only product reviews. The final review found no P0 blockers and classified the product as mature rather than an internal-tool skeleton.
- Desktop 1440x1000 and mobile 390x844 browser acceptance used a separate SQLite database and loopback port 18766.
- All five workflow stages, activity, code, and all three settings tabs loaded with no console errors or page-level horizontal overflow.
- Mobile requirement list/detail navigation, return path, horizontally contained stage navigation, and AI request-preview dialog passed.
- The Git view loaded 35 real changed files, produced complete risk/verification guidance, and exposed a 240,291-character raw patch containing `diff --git` markers.
- Development report and release candidate rendered five cells into five grid tracks with no phantom column.
- The local product page remains isolated from host 136 and SongYueGe.

### M2 result

M2 is complete and pushed. DevCycle is a release-candidate product surface, not a compatibility shell: AI is optional, manual operation remains complete, outbound model behavior is reviewable, Agent processes are real and durable, and release readiness remains evidence-derived. Public tagging is deferred until all suite modules and cross-product acceptance are complete.

## M3 InfraScout delivery checkpoint

Repository: `GeneJie199/infrastructure-discovery`

- Commits: `5b8e38ed10c77e8d35af1356a50e13539bf458fa` (complete discovery workflow) and `f84245c322849edf1f10f00760341fbca455a4a1` (real-database visibility calibration).
- GitHub CI: <https://github.com/GeneJie199/infrastructure-discovery/actions/runs/32588046650> passed on Windows, macOS, and Linux; the final calibration run is <https://github.com/GeneJie199/infrastructure-discovery/actions/runs/32588878098>.
- Local tests, vet, Staticcheck, actionlint, Bash syntax/install smoke, Linux cross-build, and JavaScript syntax passed. The prior Govulncheck run found no reachable vulnerabilities.
- Kimi K3's first final audit found one release blocker: volatile PID evidence participated in relationship fingerprints. Evidence was removed from relationship comparison identity, a restart-stability regression test was added, and Kimi's repeated audit returned `VERDICT: GO`.

### Product surface

- `infrascout up` performs first discovery, approved baseline/current state, drift, monitoring plan, local Viewer, and optional browser launch in one command; headless use is supported with `--no-open`.
- Native host, process, endpoint, systemd, Docker, Compose, network, volume, Nginx, deployment, application, database, exposure, relationship, evidence, observation, and ChangeEvent data is collected without Prometheus.
- systemd absence degrades to a warning; restart/autostart/unit, container health/restart/network/mount, and address-aware Nginx upstream relationships are retained.
- PostgreSQL/MySQL metadata v2 captures database name, schemas, tables, columns, PK/unique/FK/check constraints, indexes, views, triggers, routines, roles/users, and privileges in read-only transactions without business-row queries.
- Database and topology changes merge into the main fingerprint, decision, blocking risk, ChangeEvent, CLI/Web review, `check --fail-on`, and single-change promotion workflow.
- Relationship evidence remains available for operators but volatile evidence such as PIDs no longer creates drift or invalidates approvals. Added-table promotion retains columns as separate pending changes.
- Review mutations require a same-origin custom header, remote mutation remains disabled, sensitive CLI/DSN forms are redacted, and release artifacts include the installer, systemd unit, and checksums.

### Real database acceptance

Host 136 was used only through random containers `infrascout-m3-*-99b249c6e1` / `infrascout-m3-*-0567470932`, random loopback ports, and matching `/tmp/infrascout-m3-*` paths. No SongYueGe directory, service, container, network, volume, port, or data was enumerated or modified. Both acceptance sets were removed and their absence was verified.

- Disposable PostgreSQL 16 and MySQL 8.4 instances exposed tables, seven columns, four primary/unique/foreign-key constraints, indexes, a view, triggers, a routine, roles/users, and privileges to the collector with no warnings after documented permissions.
- PostgreSQL's read-only catalog path returned four constraints and two trigger events for a normal metadata account; MySQL returned four constraints and one trigger under the documented `TRIGGER`/`mysql.user` visibility permissions.
- After adding a column, constraint, role, and privilege, both engines produced five database changes, `CRITICAL` database and unified blocking risk, five unified database ChangeEvents, and the expected non-zero `check --fail-on critical` result.
- Approving and promoting only `dbmeta:column:public.orders.total_cents` removed that one item while four unrelated constraint/role/privilege changes remained blocking.

### UX acceptance

- The offline Lucide UI exposes seven functional views: overview, applications, assets, exposure/dependencies, changes, database, and FleetScope handoff.
- Desktop and 390x844 mobile checks covered all views with no console errors or whole-page horizontal overflow; resource details use a responsive drawer/dialog and the mobile database view remains usable.
- The final change queue displayed eight localized infrastructure/database items, stable severity/classification states, evidence, asset location, review, and promotion paths.
- The local Viewer remains available at `http://127.0.0.1:18765/`; this page and DevCycle's `http://127.0.0.1:18766/` are isolated from host 136 and SongYueGe.

### M3 result

M3 is complete and pushed. InfraScout is a self-contained discovery and drift product with native collectors, typed topology, real read-only database metadata, unified review/gating, install/service assets, and a responsive operational UI. Public tagging remains deferred until FleetScope, ReleaseGuard, protocol/design convergence, suite integration, and RC/public-asset acceptance are complete.
