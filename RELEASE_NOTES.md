# AI Engineering Team v2.0.0-rc.4 Community

This candidate includes DevCycle rc.3 and FleetScope rc.3. InfraScout,
ReleaseGuard and lifecycle-spec remain at their published rc.2 versions.

Delivery now opens for pending and R4-blocked Missions with no execution
records. Users can inspect incomplete work and risks and download the evidence
ZIP. The release status reflects the Mission's actual readiness.

FleetScope's history compaction streams retained records into the replacement
file when a node crosses the retention limit. This preserves the entry and byte
limits, record order, newline handling and atomic replacement. In an isolated
Linux amd64 comparison with 2,001 synthetic reports, the revised compaction
reduced the test cgroup's peak memory from 254.5 MiB to 102.4 MiB. The new
published Suite cohort requires its own functional and uninterrupted 24-hour
stability evidence.

## Included from rc.2

The rc.2 base added browser onboarding, a Provider Center and a readable
Delivery view to the existing DevCycle AI Team runtime. Users can connect an
authorized official Codex CLI or supported API, create or select a Git project,
choose permitted Providers and machine checks, and inspect real task branches,
code differences, checks, reviews and downloadable evidence. New projects receive
repository-local Git identity defaults only when effective identity is missing.

The Suite opens the shared work entry for development, deployment guidance,
monitoring, discovery and release validation. Products remain independently
usable. Current pages share responsive navigation and persistent Light, Dark and
System appearance. Charts use recorded product data; empty states do not invent
health or activity. Page-driven business deployment and verified running previews
remain unavailable unless separately implemented and verified for a project.

Provider configuration reuses the existing service, secret store, Agent sessions
and Team sidecar. Exact configured models need a connection test before routing.
Credentials and dispatch bindings are captured consistently: changed connections
cannot inherit an older verification. Persistent API budgets count metadata and
generation requests, reserve before sending, and stop on unknown usage,
incomplete responses or exhausted limits. Separate installations do not share an
account-wide spending ledger. Paid fallback requires explicit authorization.

Official CLI authentication remains CLI-managed. Chat subscriptions do not grant
API permissions. Windows uses Credential Manager. Linux private-file storage is
an explicit opt-in with owner-only permissions and is not encrypted at rest.
Missing Kimi credentials remain blocked. Actual GPT and DeepSeek synthetic
candidate exercises are separate from final published-artifact acceptance.
This release does not claim verified three-model collaboration or a completed
24-hour stability window.

The DevCycle AI Team Runtime includes the Mission state machine,
task DAG, five agent roles, capability registry and model routing, structured
revisioned memory, R0–R4 risk assessment, execution/worktree provenance, machine
verification evidence, independent review and release candidate export. Simple
and Expert interfaces use the same runtime. InfraScout, FleetScope, ReleaseGuard
and lifecycle-spec preserve the existing product and v0.1 contract surface.

This is a release candidate for trusted single-user local environments. Generic
CLI adapters execute with the host user's permissions; worktrees and role path
checks are not an OS sandbox. Enforcing isolation policies fail closed. R4 is
blocked. ReleaseGuard GO grants no deployment permission. Production deployment,
untrusted multi-tenancy, billing, HA and marketplace integrations are not included.
Unmetered CLI usage is unknown, not an actual invoice; strict monetary/token
budgets reject unmetered adapters. Model access requires the user's own local CLI
configuration and source-export consent; no credentials are bundled.

Install using the Suite offline archive for the verified platform, verify its
SHA-256 against checksums.txt, extract it and follow docs/offline-install.md.
Use an isolated installation prefix for evaluation. Existing installations
must back up configuration and data before upgrade; use the Suite installer with
the new manifest. Run doctor and restart after upgrade. Suite rollback restores
the saved binaries/configuration; DevCycle retains original database schema 3
and keeps new Team state in a separate sidecar. Preserve the sidecar across a
rollback and do not let old binaries manage Team state.

New six-repository source is AGPL-3.0-only. Historical v1.x remains under its
original Apache-2.0 terms. Archives include license texts, third-party notices,
Suite-wide aggregate dependency inventory/SBOM and a separately checksummed Corresponding Source archive with vendored Go
dependencies. Commercial use under AGPL is allowed when its terms are met.
Commercial alternative terms remain subject to verified rights and a separate
agreement; no signed CLA, copyright transfer or third-party relicensing right
is asserted. The contributor policy is not evidence of a signed CLA.

Platform support and precise source revisions are recorded in the Suite release
manifest and final acceptance report. Cross-compilation alone is not native
installation verification. Security reports: see SECURITY.md.

Release security: affected products select edwards25519 v1.1.1 (GO-2026-4503 fix). Every published component target binary must pass govulncheck binary scanning before upload.

Aggregate runtime diagnostics expose memory, goroutines and uptime without
profiles, environment variables or credentials. Saved-port startup and navigation
preserve configured addresses; Host/Origin write protections remain enforced.
An ambiguous interrupted execution retains its evidence and is not replayed
automatically. A local Windows ReleaseGuard cold build encountered two Go
compiler crashes; a clean bounded offline build succeeded. This does not establish
the cause or prove the default cold build was repaired.

GA readiness remains an independent evidence-based decision. Public re-download,
dual-host lifecycle/functional acceptance and an actual continuous 24-hour window
must finish before being reported as passed. Historical rc.1 and unpublished
candidate evidence retains its original scope.
