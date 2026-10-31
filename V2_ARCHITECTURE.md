# v2 architecture

Status: development, local-first foundation; stable v1.0.0 remains available.

DevCycle owns AI Team Runtime, capability registry, rule-based model routing,
revisioned project memory, risk policy, DAG execution, evaluation and shared views.
The runtime uses its existing task/worktree/session/handoff/verification services.
New persistence is additive and private to DevCycle. Contracts are versioned JSON;
InfraScout, FleetScope and ReleaseGuard remain independently deployable.

The mission graph carries Project, Mission, Plan, Task, Agent/Role, Execution,
Handoff, Artifact/Evidence, Review, Risk, Budget and Memory references. A result is
complete only with successful execution-bound verification, policy checks and review
where required. Source branches remain isolated until a human integration owner
chooses to merge. ReleaseGuard decides whether to release; deployment adapters
describe how, without bypassing human approval.

Simple mode compiles a conservative mission plan; Expert supplies the same schema
with explicit roles, capability/context/budget/adapter/tool/network policies. Registry
entries reference adapters, never provider-specific business branches. Source export
requires mission consent and an explicitly allowed provider. Unknown CLI cost/tokens
are recorded as unknown; strict monetary budgets cannot use unmetered executors.

Commercial modules depend on public extension contracts. Community never imports
Enterprise, contacts a license server, activates DRM, or loses existing capabilities.
Project identity/navigation/status are public contracts, not shared database access.

See [ADR](docs/adr/0002-v2-team-runtime.md) and [master plan](V2_MASTER_PLAN.md).
