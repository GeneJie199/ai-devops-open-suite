# AI DevOps Open Suite 0.2.0

Release date: 2026-08-12

## What ships

- **DevCycle 0.2.0:** local requirement-to-candidate workflow, evidence-backed acceptance, Git/worktree integration, and real Codex/KIMI/Claude sessions.
- **InfraScout 0.2.0:** Linux infrastructure and database metadata discovery, monitoring recommendations, approved baselines, drift, risk, watch mode, and offline/Web reports.
- **FleetScope 0.2.0:** Center/Agent collection, health and history, service probes, alerts, drift approval, resource groups, monitoring coverage, and evidence-backed topology review.
- **ReleaseGuard 0.2.0:** deterministic release gates, DevCycle/Git/InfraScout/FleetScope evidence, observation windows, immutable reports, and SHA-256-bound CLI or Web approval.
- **lifecycle-spec 0.1.0:** versioned schemas, examples, Go/TypeScript types, compatibility tests, and an offline validator.

All runtime products are single Go binaries with embedded Web assets. They remain independently deployable and exchange versioned JSON or HTTP rather than importing each other's internal packages.

## Verification

Run from the suite workspace before tagging:

```powershell
.\scripts\verify-suite.ps1
```

```bash
sh ./scripts/verify-suite.sh
```

The E2E must create a DevCycle candidate, establish an InfraScout baseline, push a FleetScope node report, validate public schemas, sample the observation window, and finish with ReleaseGuard `GO`.

Browser acceptance covers desktop and mobile layouts for the four embedded consoles, including DevCycle sub-view routing, InfraScout schema browsing, FleetScope resource-group filtering/coverage/relationship review, and ReleaseGuard evidence plus immutable Web approval.

## Publish order

1. Confirm the empty public `fleet-observability` and `release-validation` repositories and all remotes.
2. Publish and tag `lifecycle-spec` as `v0.1.0`.
3. Publish and tag DevCycle, InfraScout, FleetScope, and ReleaseGuard as `v0.2.0`.
4. Publish `project-docs` after all repository links and release assets resolve.
5. Confirm each GitHub Actions release contains all platform binaries and `checksums.txt`.

Do not reuse a tag after a failed release. Fix forward, create a patch version, and keep generated reports and approvals immutable.

## Deployment boundaries

- Web listeners default to loopback. Use SSH tunnels or an authenticated reverse proxy for remote access.
- FleetScope requires Token plus TLS for non-loopback Center deployment and supports Agent mTLS.
- ReleaseGuard Web approval is disabled unless a dedicated approval token is configured; existing approvals cannot be overwritten.
- Database DSNs and write tokens come from environment variables and must use least-privilege accounts.
- The release targets local machines, labs, and small private networks. It does not replace enterprise IAM, a long-term TSDB, Kubernetes control planes, CI runners, or human change approval.

## Upgrade and rollback

Back up the configured data directory, stop the service, replace the binary, and restart using the reviewed configuration. The 0.2.0 file formats are additive relative to the earlier 0.x workspace builds. Keep the previous binary and configuration until health, core workflows, and monitoring freshness are verified.
