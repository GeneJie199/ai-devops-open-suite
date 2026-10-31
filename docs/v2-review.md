# v2 independent review and remediation

Reviewed 2026-10-31 in a separate read-only worktree through the configured coding CLI.
The initial audit identified five actionable issues. All were corrected, regression
tested and independently rechecked at DevCycle `ab4a37f`.

| Finding | Resolution and proof |
|---|---|
| P1: Expert task array ordering could omit frontend changes from QA | Inherit the latest successful execution artifact, independent of plan-array order; verify all final task heads are ancestors of the accumulated artifact |
| P1: frontend repair could lose the repaired accumulated branch | Start repair in a fresh lead worktree from the accumulated source; fresh QA/review retain both frontend and repaired backend; real Git/process regression verifies contents |
| P1: prompt text could impersonate a model-template slot | Validate and substitute model slots in original adapter configuration before expanding prompt data; dedicated process-adapter regression |
| P2: DAG ancestry could require exponential work | Memoize positive and negative reachability; test a 60-node shared-dependency graph |
| P2: object-valued review findings could bypass a conflicting failure | Parse findings as raw JSON and reject malformed, conflicting or nonempty verdicts; retain harmless identical transport replay support |

The independent follow-up reported `{"remaining_findings":[]}` for these five fixes.
Its complete bounded output is retained in the delivery reports, alongside the initial
audit. Review output is advisory evidence; actual regression tests and CI establish
the engineering result.

Additional hardening includes loopback Host validation against DNS rebinding,
same-origin mutation checks across legacy and team APIs, explicit model/source consent,
OS-held sidecar ownership, single-dispatch CAS/locking, bounded stdin context transport,
and escalation after ambiguous restart rather than automatic replay.

No claim of OS containment for trusted CLI tools is made. No AI can approve R4. No
production deployment or commercial legal agreement was executed.
