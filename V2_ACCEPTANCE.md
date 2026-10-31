# v2 C0 AI Engineering Team acceptance

Program began 2026-10-30; verification/delivery 2026-10-31 (Asia/Shanghai).
Decision: development C0 accepted against the gates recorded below. **Not v2 GA.**
Stable public releases remain v1.0.0. Work is delivered in six reviewable development
branches/PRs; no historical tag is changed and no production release is published.

## Implementation

- DevCycle owns a runnable durable Mission/DAG runtime, five roles, capability registry,
  rule-based routing/fallback/escalation, bounded budget/retries/fix/regression,
  revisioned project memory, risk gates, evaluation and execution-bound evidence.
- Simple compiles the same configuration used by Expert; the embedded `/team.html`
  page exposes both views. Expert controls registry, context, branch/worktree roots,
  budget, checks, source consent and independent-model review policy.
- Git, sessions, handoff, credential storage, verification and candidate/report services
  reuse v1. Team state has a versioned sidecar; original schema 3 is retained.
- Additive v2 schemas/offline validation coexist with unchanged v0.1 contracts.
- Shared project identity/status/navigation and public extension/entitlement/deployment
  planning interfaces establish the control-plane and commercial boundaries.

## Machine evidence

| Gate | Result |
|---|---|
| Original five-module tests/vet and suite runtime | Passed; candidate, InfraScout baseline, Fleet native Agent and ReleaseGuard GO, 8 checks and 4 observation samples |
| Runtime registry/routing/risk/memory/DAG/failure/permission/budget/recovery/evidence tests | Passed locally and through component CI |
| Audit regressions | Passed: arbitrary plan order, frontend retention across repair, prompt/model separation, bounded ancestry, malformed/conflicting verdicts |
| Independent review | Five findings fixed; independent follow-up found none remaining in those fixes |
| UI | 1440, 768 and 390 pixel viewports passed; no overflow/page errors; cross-origin mutation refused |
| Development cross-build | All five component binaries built for five platforms; 25 real assets, no digest placeholders |
| v2 Windows offline lifecycle | Passed install/runtime/doctor, interrupted upgrade recovery, state/port preservation, tampered-backup rejection, rollback, uninstall and explicit purge |
| Public v0.3.3 → v2 development | Passed upgrade and rollback, data markers, Fleet token and ports preserved |
| License | Standard full AGPL, historical Apache copy, 61 module/asset inventory entries, preserved notice texts, CycloneDX inventory, guard and negative tests |
| CI | Exact per-repository source revisions, run URLs and job results are captured in the delivery manifest |

## Real engineering missions

Mission `5b2124fd-46bc-45ce-933f-378fd1e46995` implemented DevCycle's
`docs/ai-team-quickstart.md` through Explorer → Lead → QA → independent Review.
All four executions completed with evidence; real Go checks passed. Its reviewed
artifact was integrated into the development branch as commit `7b45cc9`.

After the audit fixes, mission `2abc7ebe-8d8f-4aca-801e-553071fa3c77` used the
final Runtime build to implement the suite's evidence checklist. All four distinct
sessions/worktrees completed; QA ran the real documentation link gate and review
returned a clean structured verdict. Source artifact `bba8c27` was independently
checked before integration. Earlier failures/interruption are retained as failures,
not counted as successful acceptance.

See [runtime](AI_TEAM_RUNTIME.md), [review](docs/v2-review.md),
[risks](docs/v2-known-risks.md) and [license audit](docs/v2-license-audit.md).
The delivery archive contains source snapshots, vendored build-dependency source
archives, offline installer, reports, complete commits/changed files and SHA-256 manifest.
