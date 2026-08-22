# v1.0 Security Review

Reviewed: 2026-08-23

Scope: lifecycle-spec, DevCycle, InfraScout, FleetScope, ReleaseGuard, and the Open Suite installers, controller, offline builder, CI, and release workflows.

## Result

No known release-blocking security finding remains at this checkpoint. The review preserves loopback/authentication/privacy defaults and introduces no new hosted service, paid dependency, or production access.

## Automated Gates

- `gosec` 2.28.0 scans every Go package directory at high severity and high confidence.
- `gitleaks` 8.30.1 scans full Git history; only exact synthetic test fixtures are allowlisted.
- `govulncheck` 1.6.0 checks reachable Go vulnerabilities.
- Staticcheck 0.7.0, `go vet`, and the Go race detector run in CI/release gates where applicable.
- Five malformed-input fuzz targets cover protocol validation, AI plan output, infrastructure parsing, telemetry compatibility parsing, and ReleaseGuard plan decoding.
- Release workflows publish SHA-256 checksums, CycloneDX SBOMs, and GitHub build provenance attestations.

## Manual Review

| Category | Result |
|---|---|
| Insecure default / debug exposure | All product viewers bind to loopback by default; remote Fleet and approval paths require explicit authentication and TLS policy |
| File permissions | credentials, database files, journals, tokens, telemetry/event segments, and temporary metadata use restrictive permissions on supported Unix paths |
| Temporary files / traversal | installers stage below guarded roots, verify resolved purge targets, use randomized temporary paths, and never build deletion commands from cross-shell enumeration |
| Shell / command injection | product subprocesses use explicit executable/argument APIs; ReleaseGuard command checks remain a disclosed trusted-plan shell boundary |
| SSRF | Fleet outbound URLs reject credentials and unsafe schemes, resolve and validate the actual dial IP, block metadata/special ranges, disable proxy inheritance and redirects, and require explicit private-network opt-in |
| Unsafe headers | transport-controlled names and CR/LF values are rejected before webhook or AI requests |
| Authentication assumptions | management, node, and approval credentials are separate; node credentials are bound and revocable; viewers do not imply authorization beyond their documented local boundary |
| AI data leakage | provider requests require a bounded preview; source, secrets, raw environment values, private keys, and business rows are excluded/redacted |
| Log redaction | known secret, DSN, authorization, private-key, and environment patterns have deterministic redaction fixtures |
| Offline integrity | every bundled component and protocol archive is manifest-pinned and SHA-256 checked; a mismatch is a hard failure with no network fallback |

## Findings Fixed

1. FleetScope webhook, SMTP, and AI destinations previously trusted the configured URL after ordinary client resolution. They now enforce DNS/IP policy at connect time, block redirects and URL credentials, and permanently deny cloud-metadata, link-local, documentation, and special-purpose ranges.
2. FleetScope custom outbound headers could include transport-controlled names or newline characters. Header names and values now receive strict validation.
3. Component installers did not all verify standalone archive checksums consistently. DevCycle, InfraScout, and FleetScope installers now accept and verify the published checksum manifest on Windows and Unix paths.
4. Telemetry memory repeated immutable metric metadata on every point. Series metadata is now stored once, reducing the measured 100-node heap from roughly 1.598 GiB to roughly 271 MiB.
5. Bounded telemetry and event stores could reject fresh data after reaching an in-memory cap. Both now retain a rolling latest window; durable segment retention remains separately bounded by time.

## Audited Exceptions

- InfraScout uses SHA-1 only to preserve previously published stable resource identifiers. It is not used for secrets, authentication, integrity, or signatures; changing it would break v0.3 identity and drift compatibility.
- DevCycle Agent adapters execute the user's selected local developer tool and ReleaseGuard `command` checks execute reviewed plan commands. These are explicit trusted-local-code boundaries, not remote command interfaces.
- lifecycle-validate reads a user-selected local document. The path is not combined with a privileged root and the validator does not write, execute, or fetch content.
- InfraScout's Linux host collector writes fixed OS fact files into a newly created process-private temporary snapshot. The audited G703 suppression is limited to that destination write; the directory is mode-restricted and removed after parsing.
- Three `.gitleaks.toml` rules allow only exact fake credentials in named test files. They do not suppress the same patterns elsewhere.

## Review Independence

Kimi K3 completed the full M6 information-architecture and visual review. A separate M7 read-only code audit began and completed two repositories before the local Kimi service returned a quota error; no unreviewed generated patch was accepted. Codex then completed the full manual and automated security pass across all six repositories. The Kimi quota limit is an audit-tool availability limitation, not a product runtime dependency.
