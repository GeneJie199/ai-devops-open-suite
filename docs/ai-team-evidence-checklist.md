# AI Team Mission evidence checklist

Use this checklist before accepting a Mission's completion or preparing a release.
See [AI Team runtime](../AI_TEAM_RUNTIME.md) and [risk policy](../RISK_MODEL.md).

- [ ] **Inspect the Mission.** Open DevCycle `/team.html` or use
  `GET /api/team/missions/{id}` to inspect requirements, acceptance criteria,
  plan/task dependencies, risk, budgets, policies, executions and evidence IDs.
  GET requests do not start execution. Check recorded risk reasons and required gates;
  a user cannot lower the automatically assessed risk floor.
- [ ] **Match evidence to the execution.** Verify mission, execution and session
  identities, provider/model, source branch/HEAD, duration, retry/escalation history,
  test/review outcomes and the SHA-256 of the bounded redacted log.
  Inspect failed attempts retained across retries as well as the final attempt.
- [ ] **Require successful machine checks.** Confirm the configured commands passed
  and their execution evidence was persisted for the relevant source HEAD.
  A process exit or an agent's completion assertion cannot replace required evidence.
  Acceptance covers the configured command/review scope, not untested product behavior.
- [ ] **Inspect independent review.** Where policy requires review, check successful
  structured verdicts and reviewer session identities distinct from the authors.
  A separate model/provider is recommended when available; findings fail review.
  QA depends on implementation and review depends on QA. After repairs, inspect fresh
  QA/review evidence. R3 requires two successful reviews and configured
  integration/security checks, plus a release candidate.
- [ ] **Confirm clean task branches.** Verify each task used a unique branch/worktree,
  inherited source serially from the last completed task's commit and stayed within
  allowed paths. Confirm committed clean state and final task HEAD/clean-state rechecks
  before Mission completion. Explorer/review must leave source and HEAD unchanged.
  Git boundary checks are not OS isolation. The runtime does not merge main automatically.
- [ ] **Keep the human release gate separate.** Mission completion and a release
  candidate do not authorize production deployment. R4 is never automatically
  dispatched or approved; production requires a separately authenticated human workflow.
  An API boolean or AI-generated human-override record cannot grant that approval.
  The deployment extension describes plans and does not execute infrastructure changes.
