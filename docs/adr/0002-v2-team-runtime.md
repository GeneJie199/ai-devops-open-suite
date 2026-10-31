# ADR 0002: Extend DevCycle with a local AI Team runtime

Accepted: 2026-10-30.

DevCycle already owns worktrees, sessions, credentials and evidence. Put mission
orchestration there, with a pure policy package and a persistence/service boundary.
Reuse the process manager and Git methods. Preserve existing schemas and add new
contracts beside them. Use a separately versioned additive SQLite sidecar for team
state so v1's schema-version guard does not break binary rollback of its original DB.

Serial dispatch is sufficient for the first embedded scheduler. Durable transitions
precede side effects. Recovery interrupts ambiguous running executions and requires
an explicit retry; it never silently duplicates a process. Retry/fallback/budget are
bounded. A CLI's exit code cannot alone approve a mission. Verification and review
are required according to risk. R4 cannot be approved by this runtime.

Reject a suite monolith, a second Git implementation, a message bus, per-vendor
workflow branches, two Simple/Expert engines, and a commercial core dependency.

Worktree isolation and post-execution path validation contain integration damage;
they are not an operating-system security sandbox. Enforced tool/network restrictions
require an executor declaring and implementing that capability. Refuse restrictive
missions on adapters that cannot enforce them rather than relying on prompts.
