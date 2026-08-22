# M7 Hardening, Scale, Security, and Documentation Checkpoint

Date: 2026-08-23
Result: PASS
Next: M8 unique v1.0.0 RC and public-asset acceptance

## Exact Component Commits

| Repository | Main commit | GitHub CI |
|---|---|---|
| lifecycle-spec | `7b93aa2019e22d6c574516dfb86cfc020b32ec43` | run `32605773468`, pass |
| DevCycle | `207d2016ba008c18318f7aa4831d35330a09d388` | run `32605773644`, pass |
| InfraScout | `eedcbf32f3c981f78ed7e0b497e350c454e5bcf2` | run `32605912865`, pass |
| FleetScope | `1912a3d2f0fe1f737ab688a08189c8852045cb72` | run `32605773947`, pass |
| ReleaseGuard | `6e7ebb6f9cd27f31a3d786a0602d033a73a01d12` | run `32605773223`, pass |

InfraScout run `32605773254` is intentionally retained as a failed audit record. Linux-only gosec taint analysis flagged the private temporary host-snapshot destination; the boundary was documented in code, committed under `eedcbf3`, and the complete three-platform pipeline then passed.

## Code and Security Gates

- All five Go modules passed full Windows tests and `go vet` after the final code changes.
- Staticcheck 0.7.0 passed all modules.
- govulncheck 1.6.0 reported no reachable vulnerabilities. InfraScout, FleetScope, and ReleaseGuard have one imported-package advisory with no reachable symbol.
- GitHub Linux jobs passed the race detector for every module; Windows/macOS tests and builds passed.
- gosec 2.28.0 high/high and gitleaks 8.30.1 full-history scans passed all five modules; the Open Suite repository secret scan also passed.
- Five 5-second parser fuzz runs passed for protocol validation, DevCycle AI output, InfraScout Docker parsing, FleetScope compatibility formats, and ReleaseGuard plans.
- actionlint 1.7.12 passed every workflow in all six repositories.
- The complete category review and audited exceptions are recorded in [security-review.md](security-review.md).

## Reliability Matrix

| Failure class | Deterministic coverage |
|---|---|
| Agent disconnect / network recovery | metric and event spools retain failed batches, drain accepted backlog first, and preserve ordering |
| Network jitter | bounded deterministic collector jitter and retry/backoff tests |
| Duplicate / out-of-order event | sequence deduplication plus timestamp-sorted query and restart tests |
| Center restart | telemetry/event segments, source catalogs, sequences, rules, alerts, topology, and history reload tests |
| Agent restart | durable sequence and credential/spool restart tests |
| Disk write failure / full-equivalent error | segment path write failures do not mutate in-memory telemetry/events and the same batch succeeds after storage recovery |
| DB lock | ReleaseGuard waits through a real transient SQLite writer lock and completes within the configured busy timeout |
| Process crash / stale work | DevCycle recovers active verification/Agent state; ReleaseGuard leases expire and are reclaimable with audited abandon behavior |
| stale PID / service restart | suite acceptance validates executable-bound PID handling, start/stop/restart, and prior-service restart |
| interrupted upgrade | Windows/Linux acceptance kills or fails after payload replacement, verifies the durable journal and backup digest, restores the prior install, and retries |

Bounded telemetry and event memory now retains the newest window instead of rejecting fresh observations. Durable on-disk retention remains separately time-bounded.

## Install and Ownership Acceptance

- Windows FleetScope standalone acceptance used a random repository QA path and private port: checksum, start, doctor, exact-process stop, data-preserving uninstall, rejected unconfirmed purge, and confirmed purge all passed.
- Linux standalone acceptance on host 136 covered DevCycle, InfraScout, and FleetScope in `/tmp/ai-devops-m7-install.*`: checksum, install, start where applicable, doctor, uninstall-preserves-data, purge rejection, exact-confirmation purge, and cleanup passed.
- FleetScope no longer changes an existing InfraScout state directory's permissions and never removes InfraScout data during purge. The Linux ownership marker survived FleetScope deep removal.
- The one-command Windows bootstrap downloaded a locally served release-style archive and checksum, then installed all five public components online into an isolated temporary prefix.
- The one-command Linux bootstrap used the same verified release-style archive path on host 136 and installed all five public components online. Both bootstrap tests produced `ai-devops.bootstrap-acceptance/v1` evidence and removed their product test directories.

Host 136 work used only randomized `/tmp/ai-devops-m7-install.*`, `/tmp/ai-devops-bootstrap-accept.*`, and `/tmp/ai-devops-bootstrap-source.*` paths plus loopback. It did not enumerate, stop, modify, or mount the SongYueGe environment; all test paths were removed and verified absent.

## Scale

FleetScope was measured with 100 nodes, 8 metrics per node, 60-second collection, 3-day retention, 3,456,000 samples, and 43,200 events on Windows and Linux. Loaded heap fell from roughly 1.598 GiB to roughly 271 MiB after compact series storage. The verified v1.0 recommendation stops at 100 nodes per Center; exact throughput, restart, query, disk, CPU, memory, and resource guidance are in [scale-benchmark.md](scale-benchmark.md).

## Supply Chain and Documentation

- Component release workflows generate raw suite binaries, complete standalone archives, SHA-256 manifests, CycloneDX module SBOMs, and GitHub build provenance.
- The suite workflow generates five platform-specific full offline bundles, stable one-command aliases, an aggregate CycloneDX SBOM, checksums, and provenance.
- All six READMEs now follow the external-user order: Screenshot, Why, Core Features, Quick Start, Online Install, Offline Install, First Five Minutes, AI Optional, Comparison, Architecture, Security, Roadmap, and Contributing.
- Local documentation links/images, suite manifest/index generation, shell/PowerShell syntax, standalone install commands, and Windows/Linux bootstrap commands passed.

## UI Review Boundary

The complete Kimi K3 UX/visual review remains the accepted M6 evidence. A new M7 read-only Kimi audit completed two repositories before the local service returned a quota error; no generated patch was accepted without Codex review. M7 introduced no new product page or navigation model, and all four existing local pages remained HTTP 200 throughout the checkpoint.
