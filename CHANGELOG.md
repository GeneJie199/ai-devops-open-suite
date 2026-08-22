# Changelog

## Unreleased

- Start the governed v1.0 program with an audited six-repository capability matrix, executable master plan, public roadmap, platform support matrix, compatibility policy, and immutable release policy.
- Define additive lifecycle protocol evolution and a backup-first, idempotent migration requirement for every persisted v0.3 state format.
- Add a single suite manifest with exact per-platform digests, generated Bash indexes, platform-specific full offline bundle build/verification, and immutable Release workflow behavior.
- Add controller-driven upgrade and integrity-checked rollback, data-preserving uninstall, exact-path-confirmed purge, and machine-readable install/backup/uninstall state on Windows, Linux, and macOS script paths.
- Pass Windows and isolated Linux install lifecycle acceptance, Linux network-namespace offline installation, failed-commit restoration, tampered-backup rejection, and a public v0.3.3 Windows upgrade/rollback preservation test.
- Add durable interrupted-install journaling and verified next-run recovery, PowerShell 5.1 compatibility, bounded online download retry/resume behavior, and deterministic acceptance-only failure injection restricted to temporary paths.
- Pass manifest-driven online installation and public v0.3.3 migration on Linux, and preserve real DevCycle, InfraScout, FleetScope, and ReleaseGuard state fingerprints through upgrade and rollback on Windows and Linux.

## 0.3.3 - 2026-08-13

- Fix the suite Release publication shell block after the failed `v0.3.2` packaging tag; the failed tag is retained for audit and is not reused.
- Separate the `0.3.3` umbrella suite version from the verified `0.3.2` product asset version so installation status and Fleet labels remain truthful.

## 0.3.2 - 2026-08-13

- Add checksum-verified cross-platform suite installers and a single `suitectl` entry point for initialization, start, stop, restart, status, browser opening, and logs.
- Make installation and running upgrades transactional: stage every artifact, stop managed processes, atomically replace binaries, restore on install failure, and restart when the suite was already running.
- Add macOS-native SHA-256 support, first-run Fleet credentials, a live local Agent, safe demo data, startup rollback, and explicit Agent status.
- Validate fresh installation, first start, failure rollback, running upgrade, live Agent reporting, and clean shutdown on Windows and an isolated `/tmp` environment on 136 Linux.
- Add a three-minute quick start, offline installation layout, release archives, CI syntax checks, and refreshed product screenshots.
- Add persisted port configuration, actionable `doctor` diagnostics, Windows Startup/Linux user-systemd/macOS LaunchAgent autostart, and stale-PID executable validation.
- Accept LF or CRLF checksum manifests so offline release assets can move safely between operating systems.
- Resolve the final interaction audit findings for live-output disclosure state, current-evidence semantics, risk-queue reconciliation, and uninterrupted Fleet triage.
- Enforce ReleaseGuard approval binding to the currently served report digest while retaining prior immutable approvals for audit when a report path is reused.

## 0.3.1 - 2026-08-12

- Replace the external-collector/TSDB assumption with a native FleetScope data-plane architecture and compatibility-only ecosystem inputs.
- Require source-pinned DevCycle candidates and native metric regression in the cross-module delivery gate.
- Unify the four product headers, configurable suite navigation, contextual handoffs, responsive acceptance, and current screenshots.
- Document the immutable `0.3.0-rc.2` cross-platform, security-gated publishing process and isolated 136 acceptance requirement.
- Ship reproducible PowerShell and Bash suite verification scripts and record the isolated Linux acceptance result.
- Verify all 36 downloaded GitHub Release assets against GitHub digests, all 31 business assets against published checksums, and the downloaded Linux amd64 suite on 136 before allowing the stable release.
- Record the published-asset `v0.3.0` NO-GO caused by a transient CPU health misclassification, retain it as a Pre-release audit record, and deliver the corrected `v0.3.1` suite.
- Re-download and verify all `v0.3.1` assets, execute the Windows binaries, and pass the isolated 136 published-asset gate twice consecutively.

## 0.2.0 - 2026-08-12

- Document the independently deployable five-repository suite and its versioned JSON integration boundaries.
- Add local and isolated-host end-to-end verification instructions for the requirement-to-release workflow.
- Add deployment, security, troubleshooting, operations, contribution, and release documentation.
- Record the completed DevCycle, InfraScout, FleetScope, ReleaseGuard, and lifecycle-spec release scope.
