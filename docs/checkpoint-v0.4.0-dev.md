# v0.4.0-dev Installation Lifecycle Checkpoint

Date: 2026-08-22
Scope: M1 development checkpoint, not a public release

## Implemented

- `ai-devops.suite-manifest/v1` pins repository, tag, component version, platform asset, target name, and SHA-256.
- Generated per-platform install indexes let Bash consume the same manifest without requiring Python or `jq` on the target host.
- The full offline builder packages all five executables, the lifecycle protocol archive, installer/controller, manifest, file digests, documentation, and examples.
- The offline verifier rejects unsafe archive paths, links, undeclared files, stale indexes, non-executable Unix installers, and component/protocol digest mismatches.
- `suitectl` supports version, upgrade, rollback, uninstall, and purge. Upgrade backups are persistent and integrity checked before rollback.
- Uninstall preserves data/config/logs/protocols/backups. Purge requires the exact canonical suite path and refuses roots and links/reparse points.
- Release workflow refuses an existing Release, requires tag/manifest agreement, builds all offline platforms, verifies them, and creates GitHub build provenance.

## Windows amd64 acceptance

- Full offline install: pass.
- Four services and local Fleet Agent on dynamic loopback ports: pass.
- Doctor: pass.
- Controller-driven upgrade and explicit rollback: pass.
- User data marker across rollback and uninstall: pass.
- Default uninstall leaves zero managed binaries and preserves data: pass.
- Exact-path-confirmed purge: pass.
- Missing offline asset with network fallback disabled: correctly rejected.
- Tampered backup binary: correctly rejected before any rollback mutation.

The current development installer was also applied to a clean installation created from the public Open Suite v0.3.3 ZIP. Four product data markers, the Fleet token, and persisted port configuration survived upgrade and rollback. Rollback restored `suite-version` to `0.3.3`.

## Linux amd64 acceptance

Host 136 was used only in random `/tmp/ai-devops-v1-accept.*` paths and dynamic loopback ports. No SongYueGe path, service, container, or data was accessed or modified.

- Full offline install, start, Agent, four service endpoints, Doctor, stop: pass.
- Controller-driven upgrade, rollback, uninstall-preserve, reinstall, purge: pass.
- Forced post-binary protocol commit failure restored the prior binary: pass.
- Tampered persistent backup was rejected: pass.
- Missing local asset did not fall back to the network: pass.
- A separate root network namespace with no network interfaces ran only installer/controller initialization and wrote an offline five-component install state: pass.
- All remote acceptance directories were removed after the test.

InfraScout reported Docker socket permission as a warning for the unprivileged user; this was expected and avoided reading unrelated containers.

## Bundle structure verification

All five platform archives passed the offline verifier. These local development digests are evidence only and are not public release claims:

| Platform | Archive size | SHA-256 |
|---|---:|---|
| Windows amd64 | 22,555,858 | `6b8bce2e726843ea69013a77e5c34844b139771213ff24c237bd3290e8d21504` |
| Linux amd64 | 22,078,871 | `01b9e76149557eeedb28d2d4d7465ef6b64480f805e9c7055605520da46b65cc` |
| Linux arm64 | 20,194,689 | `f1cda125d34cf910c51d94fc957ae3e6ba2da8ff7d7f62cd29613a611834f610` |
| macOS amd64 | 22,351,318 | `4ac152c3455966dea907d0b4ab88a6cba7570928e2d765f29c0d23fb5f57432b` |
| macOS arm64 | 20,915,572 | `6986a3eca6f1c077e9b5f3f6504e08b73f7599c64dcacda824dbf3574a43bcc5` |

## Remaining before M1 closes

- Run the public v0.3.3 migration preservation test on Linux.
- Add interruption/power-loss journaling and recovery acceptance.
- Rebuild all bundles from v1 component releases and generate component SBOMs before RC.
- Keep macOS and Linux arm64 at build-tested status until native runtime evidence exists.
