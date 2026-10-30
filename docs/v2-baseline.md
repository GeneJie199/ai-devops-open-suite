# v2 baseline audit

Audited 2026-10-30 from fresh complete clones. All started clean on main. No AGENTS.md
was found in the six checkouts. No product packages or databases are embedded in the
umbrella repository. Existing CI/release configuration and v1 acceptance documents
were inspected; historical acceptance is not a substitute for new execution reports.

| Repository | Starting HEAD | Reusable capability | v2 gap |
|---|---|---|---|
| Open Suite | 039d63a | manifest, checksum installer, durable upgrade/rollback, offline builder, provenance/SBOM | runtime integration documentation, license inventory and guard |
| DevCycle | 2ed6e54 | SQLite schema 3; requirements, criteria, dependencies, five CLI adapters, API providers, keyring/env secrets, preview/redaction, worktree/handoff, verification/evidence/RC | mission scheduler, capability routing, project memory, explicit risk/budget/evaluation |
| InfraScout | b881a03 | host/container/DB metadata discovery, baseline/drift, portable evidence | shared project reference |
| FleetScope | f1ebb93 | native agent/store, topology, alerts, evidence | shared project reference |
| ReleaseGuard | 8e0d7e8 | deterministic preflight/observation, recovery, digest-bound human approval | execution vs decision contract |
| lifecycle-spec | 37f13ac | immutable v0.1 schemas, offline validator, generated Go/TS types | additive v2 team/control contracts |

DevCycle's `internal/agent/adapters.go` defines Codex, Claude, Gemini, Kimi and OpenCode
argv templates. `internal/app/workflow.go` manages processes, bounded redacting logs,
verification and restart interruption. `internal/app/ai_providers.go` owns provider
configuration/connection tests and keyring/env credential replacement/revocation.
`internal/git/worktree.go` is the existing Git orchestration boundary. Handoffs and
evidence already live in the private store. Model/cost usage is explicitly unreported
by existing CLI sessions; zero must never be presented as measured usage.

Current remote suite and all five component latest runs report success. Local docs,
manifest validation and four manifest tests passed before edits. Full Go/vet/runtime
baseline is being collected in `baseline-suite.log` and final reports.

## Copyright and supply chain

Complete Git shortlogs show GeneJie/genejie199@gmail.com throughout, plus the
GeneJie199 GitHub noreply identity in DevCycle's initial scaffold. Existing LICENSE
names Copyright 2026 GeneJie199. GitHub PR inventory is checked separately in audit
evidence. No company ownership is inferred. This establishes repository provenance,
not a warranty that undisclosed employment/contract obligations do not exist.

Vendored Lucide carries its own ISC/Feather notices. Go dependencies are external
modules; their licenses must be inventoried and preserved rather than relabeled AGPL.
Historical Apache binaries in the v1 suite manifest remain Apache-licensed even when
packaged beside future AGPL source. Screenshots have no separately declared author
in repository metadata; retain their existing project provenance and record uncertainty.

## Architecture confirmation

Extend DevCycle, do not create another product runtime or merge four private stores.
Keep scheduling local and serial initially. Every execution gets a task-owned
worktree through existing DevCycle methods. No automatic main merge or production
release. Unknown availability, cost, permission or evidence must fail closed where
required by a mission policy. Simple compiles to the same Expert configuration.
