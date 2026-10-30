# v2 AI Engineering Team master plan

Date: 2026-10-30. Status: implementation in progress; not GA.

## Baseline and scope

The umbrella repository at `039d63a` contains packaging, installers, documentation and
release gates, not product source. Five sibling Go modules own the four products and
contracts. Stable remains v1.0.0; its manifest, tags and licensed releases are immutable.
See [baseline](docs/v2-baseline.md) and [architecture](V2_ARCHITECTURE.md).

## Execution plan and acceptance

1. M0: audit six repositories, ownership, adapters, contracts, dependencies and tests;
   record the architecture before changing runtime code.
2. M1–M3: add a local, durable AI Team runtime inside DevCycle, a validated capability
   registry and deterministic capability/cost/context/risk/availability routing. Reuse
   its existing CLI session manager, task worktrees and redacting logs.
3. M4–M6: structured revisioned memory, conservative risk gates, validated DAG,
   persisted execution/evidence, bounded retries, escalation and recovery. Do not
   interpret an agent's completion message as machine verification.
4. M7–M9: one configuration/runtime for Simple and Expert, public project identity
   and navigation/status contracts, evaluation and commercial extension interfaces.
5. Licensing: preserve Apache historical copies and third-party notices; migrate
   development Community source to standard AGPL-3.0-only after provenance review;
   document commercial/OEM, contributor and trademark boundaries.
6. Quality: negative-path runtime tests, full original suite gate, static/security
   checks, installer lifecycle, real opt-in CLI mission and independent review.
7. Delivery: logical commits, exact source snapshots, reports and SHA-256 manifest in
   `AI-DEV-V2-C0-DELIVERY.zip`. Report every unexecuted gate or unsupported feature.

No production deployment, published release, billing, distributed scheduler, new Git
orchestration or enterprise feature removal is part of this change. R4 execution
remains blocked for a separately authenticated human-controlled production workflow.

## Progress

- [x] Restore and inspect actual six-repository layout and current remote CI.
- [x] Record capability map, reuse decisions and v2 gaps.
- [ ] Runtime, routing, memory, orchestration and shared views.
- [ ] Licensing, offline metadata and extension boundaries.
- [ ] Tests, review, fixes, verification and real mission.
- [ ] Delivery with exact results and remaining risks.
