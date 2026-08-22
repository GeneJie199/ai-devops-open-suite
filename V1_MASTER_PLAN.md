# AI DevOps Open Suite v1.0 Master Plan

Status: ACTIVE  
Started: 2026-08-22  
Owner: suite maintainers  
Target: a trustworthy, publicly installable v1.0 GA, followed by public-asset smoke tests

This plan is the execution source of truth for the v1.0 program. It is updated at every checkpoint. A checked item means implementation, review, tests, and recorded evidence have all completed; it does not mean that documentation alone was changed.

## 1. Product contract

AI DevOps Open Suite is a local-first development and operations suite for the AI development era. The four products remain independently installable and communicate only through versioned JSON, HTTP APIs, and artifacts defined by `lifecycle-spec`.

The v1.0 priorities, in order, are:

1. Data safety and recoverability.
2. Clean install, upgrade, rollback, and uninstall reliability.
3. Correct deterministic product behavior.
4. Useful zero-configuration defaults with progressive disclosure.
5. Native discovery and collection; ecosystem formats are compatibility inputs.
6. Evidence-backed drift, topology, alerts, AI explanations, and release decisions.
7. Honest platform, scale, and limitation claims backed by executed tests.

AI remains optional. It may plan and explain, but it may not fabricate evidence, silently export secrets, approve production risk, or mutate infrastructure without a separate explicit human-controlled action.

## 2. Audited baseline

| Repository | Published version | Baseline main commit | Verified baseline |
|---|---:|---|---|
| `lifecycle-spec` | 0.1.1 | `2c9853b7e1959d2ceaaf7289aa5f4a2af0f5f5bd` | clean/synced, tests and vet pass |
| `ai-dev-cycle-manager` | 0.3.2 | `146bced213c2f9c4db8a9d96850822f756feac94` | clean/synced, tests and vet pass |
| `infrastructure-discovery` | 0.3.2 | `7f0765d2e95bce56a69ac486b1924eb018b2e6f1` | clean/synced, tests and vet pass |
| `fleet-observability` | 0.3.2 | `e8c2007fd17ba4a368eb1a81028766bb9db3990a` | clean/synced, tests and vet pass |
| `release-validation` | 0.3.2 | `5c299f06179b14cbcaaef8522f7a25005bbb10ea` | clean/synced, tests and vet pass |
| `ai-devops-open-suite` | 0.3.3 | `b909998e8bf57771400b06939b6903e132e9b5f9` | clean/synced, CI/release assets verified |

Baseline verification was repeated on 2026-08-22. All five Go modules passed `go test ./...` and `go vet ./...`. The six repositories were on `main`, tracking `origin/main`, with no local or remote divergence and no open issues or pull requests.

## 3. Delivery strategy

The internal v0.4-v0.9 labels are engineering checkpoints, not promises to publish every intermediate tag. A checkpoint can reuse already completed work. Public prereleases are created only when they materially improve packaging or upgrade validation.

Protocol evolution is additive:

- Existing `schemas/v0.1` and its examples remain valid and testable.
- New stable v1 contracts are added alongside v0.1, never silently substituted.
- Readers accept supported older contracts or fail with an actionable version error.
- Persisted v0.3 data receives explicit, idempotent migrations and backup/rollback coverage.

Product releases converge on `v1.0.0`. The umbrella suite release converges on `v1.0.0` only after every referenced component release and public asset has passed its own gate.

## 4. Milestones

### M0 - Baseline and governance

- [x] Fetch and audit all six repositories, main branches, remotes, commits, releases, CI, documentation, and clean status.
- [x] Re-run all existing Go tests and vet checks.
- [x] Establish the current capability and gap matrix.
- [x] Publish this master plan, current status, roadmap, compatibility matrix, support matrix, and release policy.
- [x] Create a public v1.0 milestone and scoped GitHub issues.
- [x] Record protocol and persisted-data compatibility decisions as ADRs.

Exit evidence: committed planning documents, public milestone/issues, exact baseline commits, green baseline CI.

### M1 - Productization and zero-friction lifecycle

- [x] Replace per-repository version arguments with a checksummed suite manifest; release attestation is wired into the GA workflow.
- [x] Build and structurally verify complete offline bundles for every advertised artifact platform.
- [x] Prove Linux amd64 offline install in an isolated network namespace with no product service started and no external cache.
- [x] Add first-class `upgrade`, `rollback`, and `uninstall`; make data purge a separate exact-path-confirmed command.
- [x] Preserve configuration, ports, token/identity, state, snapshots, approvals, and releases across upgrade.
- [x] Make install failures and interrupted upgrades recover to the prior working binaries.
- [x] Produce machine-readable installation, backup, uninstall, and bundle metadata; keep actionable doctor output.

Exit evidence: clean online/offline install, v0.3-to-current upgrade, rollback, restart, uninstall-with-data-preserved, explicit purge tests on Windows and Linux.

### M2 - DevCycle requirement-first workflow

- [ ] Make “What do you want AI to build?” the primary new-user path while retaining full manual operation.
- [ ] Expand planning output to understanding, scope, assumptions, missing information, acceptance criteria, test cases, test plan, tasks, agent suggestions, order, risks, rollback concerns, and candidate notes.
- [ ] Add configurable AI providers: OpenAI-compatible, Anthropic, Gemini, local OpenAI-compatible/Ollama-style, and custom adapters.
- [ ] Store secrets outside normal logs/evidence/Git and provide a redacted request preview.
- [ ] Add Codex, Claude Code, Gemini CLI, Kimi, OpenCode, and custom Agent adapter definitions without embedding an agent implementation.
- [ ] Complete task handoff, lifecycle state, worktree ownership, bounded logs, diff, test, and evidence links.
- [ ] Extend humanized Git with user/API/database/configuration impact, risk, and suggested verification; retain raw diff.
- [ ] Support evidence kinds for code, commit, test, screenshot, command, HTTP response, artifact, and human confirmation.

Exit evidence: complete new-user path with and without AI, deterministic evidence gate, provider/secret tests, agent interruption/restart tests, browser UX acceptance.

### M3 - InfraScout discovery and drift

- [ ] Keep `infrascout scan` useful without configuration and report unsupported collectors as warnings, not fabricated success.
- [ ] Harden host, process, endpoint, systemd, Docker, Compose, network, volume, Nginx, runtime, database, exposure, and relationship evidence.
- [ ] Normalize Host, Process, Service, Deployment, Container, Database, Endpoint, Volume, Network, Relationship, Observation, Snapshot, Evidence, and ChangeEvent through stable public contracts.
- [ ] Complete desired/approved/observed state and expected/approved/temporary/pending/unexpected/denied review semantics.
- [ ] Expand PostgreSQL/MySQL metadata to primary keys, indexes/unique, foreign keys, views, triggers, functions/procedures, users/roles, and privileges within documented engine limits.
- [ ] Keep metadata collection read-only and exclude business rows by default.
- [ ] Add database baseline/review/evidence integration and release correlation.

Exit evidence: zero-config scan, structured infrastructure diff, database metadata diff against disposable PostgreSQL/MySQL, noise filtering, review expiry and baseline promotion tests.

### M4 - FleetScope fleet operations

- [ ] Make fleet triage the default: needs action, needs attention, healthy, offline, followed by dense comparison views.
- [ ] Complete install, secure enrollment, auto-registration, discovery ingestion, recommendations, and one-action monitoring enablement.
- [ ] Harden native host, Docker, PostgreSQL, MySQL, Redis, HTTP/Nginx, and TLS collectors; retain Prometheus/Influx/OTLP as optional inputs only.
- [ ] Persist topology snapshots and implement topology diff by time/group/release/incident.
- [ ] Cover deployment, service dependency, database dependency, exposure, monitoring coverage, and incident impact views.
- [ ] Preserve relationship source, confidence, evidence, first/last seen, confirm/correct/ignore/manual audit state.
- [ ] Complete the Change Center across host, deployment, Docker, service, network, database, and topology drift.
- [ ] Add durable alert delivery with dedupe, grouping, suppression, stabilization, deployment windows, retries, and bounded queues.
- [ ] Ship a maintainable channel set: generic webhook plus Feishu, WeCom, DingTalk, Slack, Telegram, and SMTP where reliable; document security and retry behavior.
- [ ] Add evidence-package generation and redacted AI preview/explanation with evidence, assumptions, and confidence sections.

Exit evidence: multi-node auto-onboarding, topology snapshot/diff, Change Center actions, collector fault isolation, alert storm controls, delivery retry tests, AI privacy tests, browser UX acceptance.

### M5 - ReleaseGuard lifecycle integration

- [ ] Accept DevCycle candidates and versioned expected infrastructure/database changes.
- [ ] Correlate release, InfraScout/DB drift, Fleet health/topology/change, metric regression, version consistency, and observation windows.
- [ ] Verify environment contract, migrations, smoke/HTTP/script checks, rollback readiness, and expected-change coverage.
- [ ] Keep final reports immutable and approvals cryptographically bound to the exact report digest.
- [ ] Add evidence-backed explanations while retaining human-only approval authority.

Exit evidence: candidate to preflight to expected changes to observation to final report, including negative-path and restart/resume tests.

### M6 - Unified design system and product UX

- [ ] Publish and apply Open Suite typography, spacing, radius, icon, button, form, table, status, alert, dialog, navigation, empty/loading/error, chart, and topology patterns.
- [ ] Complete onboarding and progressive disclosure for all four products.
- [ ] Use familiar icons for controls, clear text for commands, compact operational layouts, and no decorative dashboard clutter.
- [ ] Pass desktop, tablet, and mobile regression without whole-page horizontal overflow.
- [ ] Pass keyboard, focus, contrast, dialog, error recovery, and basic accessible-name checks.
- [ ] Run Kimi K3 information architecture, visual hierarchy, layout, onboarding, empty state, density, responsive, dashboard, and topology reviews; independently verify and implement accepted findings.

Exit evidence: Kimi review record, before/after screenshots, browser automation, accessibility report, responsive acceptance.

### M7 - Hardening, scale, security, and documentation

- [ ] Test disconnect, jitter, duplicate/out-of-order events, center restart, agent restart, process crash, stale PID, disk-full behavior, DB lock, and interrupted upgrade.
- [ ] Run applicable race tests, Staticcheck, govulncheck, secret scanning, malformed-input/fuzz tests, and security review.
- [ ] Audit file permissions, temp paths, traversal, command/shell injection, SSRF, debug endpoints, loopback/auth defaults, AI leakage, and log redaction.
- [ ] Generate release SBOMs, checksums, manifest, and GitHub-supported provenance/attestation.
- [ ] Benchmark ingestion, retention, disk growth, CPU, and memory; publish only measured recommended scale.
- [ ] Rebuild all six READMEs for external users and verify every installation command.
- [ ] Publish compatibility/support matrices, known limitations, security/release policies, contribution guide, and roadmap.

Exit evidence: security and benchmark reports, generated SBOM/provenance, verified READMEs, resilience test results.

### M8 - RC, GA, and public-asset acceptance

- [ ] Build a unique v1.0 RC with full online and offline artifacts.
- [ ] Test clean install, v0.3.3 upgrade, rollback, restart, doctor, and uninstall on isolated Windows and Linux.
- [ ] Verify supported architecture bundles without claiming unexecuted native validation.
- [ ] Resolve every release blocker and rerun the complete gate.
- [ ] Merge exact reviewed commits to all six `main` branches and wait for green CI.
- [ ] Publish immutable component/spec `v1.0.0` releases, then the suite `v1.0.0` release.
- [ ] Redownload public assets and repeat Windows and Linux install/start/doctor/UI/Agent/offline-manifest smoke tests.
- [ ] If a public blocker is found, fix it under a new patch tag; never replace an immutable release silently.

Exit evidence: public release URLs, asset digests, post-release smoke logs, clean/synced main commits, no known blocker.

## 5. v1.0 acceptance gates

| Gate | Required evidence |
|---|---|
| Code | all module tests/vet, applicable race, Staticcheck, govulncheck |
| CI | every advertised build and release job green |
| Install | online/offline clean install, v0.3 upgrade, rollback, restart, uninstall, doctor |
| Product | four real new-user paths and cross-product evidence path pass |
| UI | Kimi K3 review, responsive/browser tests, basic accessibility, no severe UX blocker |
| Security | secret/privacy/default exposure audit, malformed input coverage, complete asset verification |
| Supply chain | checksums, manifest, SBOM, provenance/attestation where GitHub supports it |
| Documentation | commands executed from public README/release assets, claims match tests |
| Support | measured platform matrix, scale baseline, resource guidance, known limitations |

No gate may be satisfied by a mock, a README claim, or an unexecuted platform build.

## 6. Initial support policy

The final matrix will be based on v1.0 acceptance, not build availability.

| Platform | Planned artifact | Current validation level | GA claim rule |
|---|---|---|---|
| Windows amd64 | full online/offline | native install and runtime accepted at v0.3 | supported only after v1 public smoke |
| Linux amd64 | full online/offline | isolated install and runtime accepted at v0.3 | supported only after v1 public smoke |
| Linux arm64 | full online/offline | CI build only | preview unless a native runtime gate is obtained |
| macOS amd64 | full online/offline | CI build only | preview unless a real runtime gate is obtained |
| macOS arm64 | full online/offline | CI build only | preview unless a real runtime gate is obtained |

Windows arm64 is not a v1.0 artifact target unless all component binaries and an execution environment can be validated.

## 7. Known program risks

- Upgrade tests must use copied v0.3 state and never mutate a user's live installation.
- Database tests use disposable local or isolated instances and metadata-only accounts.
- Agent and verification commands are trusted-local-code boundaries and require explicit disclosure.
- Alert destinations and AI providers may create data-export risk; preview, redaction, and opt-in controls are mandatory.
- macOS and arm64 support labels must remain below “verified” until native runtime evidence exists.
- Full offline bundles are large; correctness and integrity take priority over archive size.

## 8. Checkpoints

| Date | Checkpoint | Evidence | Result |
|---|---|---|---|
| 2026-08-22 | M0 baseline audit | six exact commits; five Go test/vet runs; releases/CI/remotes checked | pass |
| 2026-08-22 | M0 governance | commit `2526e93`; public v1.0 milestone and issues 1-8; compatibility ADR | pass |
| 2026-08-22 | M1 install lifecycle checkpoint | five offline bundles verified; Windows/Linux online and offline install; public v0.3.3 migration; real product-state preservation; process-kill recovery journal; rollback/uninstall/purge | pass |
