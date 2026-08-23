# AI DevOps Open Suite v1.0 Acceptance

Accepted: 2026-08-23
Decision: GO
Release: `v1.0.0`

## Gate result

| Gate | Result | Evidence |
|---|---|---|
| Product | Pass | DevCycle requirement/evidence flow, InfraScout discovery/drift, FleetScope native monitoring/topology/alerts, and ReleaseGuard release decision flow completed through M2-M5 |
| Code | Pass | five Go modules passed tests/vet; applicable race, Staticcheck, govulncheck, gosec, secret scan, fuzz, malformed-input, and three-platform build gates passed |
| UI | Pass | Kimi K3 review session `session_3d981a28-7f5b-433f-ac13-76037c84207d`; 12 desktop/tablet/mobile combinations; keyboard, focus, responsive, dialog, accessible-name, polling, and non-color status checks |
| Install | Pass | public README bootstrap and complete offline lifecycle on Windows amd64 and Linux amd64 |
| Upgrade | Pass | public v0.3.3 to v1.0.0, rollback to v0.3.3, second upgrade, ports/token/data preservation on Windows and Linux |
| Recovery | Pass | interrupted replacement, failed commit, stale PID, tampered backup, SQLite lock, durable spool, restart, and data-preserving uninstall tests |
| Offline | Pass | five 21-file bundles verified; Linux amd64 installed inside a no-network namespace; missing assets never fell back to the network |
| Supply chain | Pass | 71 public assets; 64 checksummed artifacts; 70 GitHub provenance subjects; six SBOM-bearing stable releases |
| Security | Pass | loopback/auth defaults, file/temp/purge safety, SSRF, injection boundaries, redaction, secrets, AI preview/privacy, and release integrity reviewed |
| Scale | Pass | 100 nodes, 3,456,000 samples, 43,200 events, 3-day retention, roughly 271 MiB loaded Go heap |
| Documentation | Pass | six external-user READMEs, public commands, local links/images, compatibility, support, security, scale, install, offline, release, and contribution documents verified |

## Public post-release smoke

Windows 11 amd64 passed the literal public README PowerShell bootstrap against `releases/latest`, five-component start, four UIs, Fleet Agent identity, `doctor`, cleanup, full offline lifecycle, and public v0.3.3 upgrade/rollback.

Ubuntu 24.04 amd64 on host 136 passed the literal public README shell bootstrap, five-component start, four UIs, Fleet Agent identity, `doctor`, all four standalone installer lifecycles, full offline lifecycle inside a network namespace, and public v0.3.3 upgrade/rollback. Only randomized `/tmp/ai-devops-*` paths and dynamic loopback ports were used; SongYueGe was not accessed or modified.

## Release inventory

| Repository | Stable tag | GA commit | Release workflow |
|---|---|---|---:|
| lifecycle-spec | `v1.0.0` | `37f13ac2ea4bc7ea5a5316d130ece6537c5dbff5` | `32611930244` |
| DevCycle | `v1.0.0` | `2ed6e54328966ca16c1aa6585b3131fb87fdaa83` | `32611935082` |
| InfraScout | `v1.0.0` | `b881a03c40fa4f11e9d9ef64f3cf6f5e229cfba6` | `32611939162` |
| FleetScope | `v1.0.0` | `f1ebb93172355132c4171a49ed9603771819222e` | `32611943459` |
| ReleaseGuard | `v1.0.0` | `8e0d7e8c9feea59e389500713a1c3a0e2bfe17b0` | `32611949369` |
| Open Suite | `v1.0.0` | `076be4e153e64c919870950fe7b67b9ff38e5ab9` | `32612562754` |

## Accepted support boundary

- Verified runtime: Windows 11 amd64 and Ubuntu 24.04 amd64.
- Build-tested artifacts only: Linux arm64, macOS amd64, macOS arm64.
- FleetScope recommendation: one Center, at most 100 nodes, 8 metrics per node at 60-second intervals, 3-day retention.
- Not claimed: Windows arm64, macOS native acceptance, high availability, enterprise IAM/RBAC/multi-tenancy, automated production remediation, or scale above 100 nodes per Center.

No known release blocker remains. No hard-stop condition was triggered.
