# M8 Release Candidate Checkpoint

Date: 2026-08-23  
Result: `v1.0.0-rc.2` passed the release-candidate gate; GA publication remains pending

## Reviewed commits

| Repository | RC2 commit | RC2 release workflow |
|---|---|---:|
| lifecycle-spec | `37f13ac2ea4bc7ea5a5316d130ece6537c5dbff5` | `32608884772` |
| DevCycle | `2ed6e54328966ca16c1aa6585b3131fb87fdaa83` | `32608887394` |
| InfraScout | `b881a03c40fa4f11e9d9ef64f3cf6f5e229cfba6` | `32608890134` |
| FleetScope | `f1ebb93172355132c4171a49ed9603771819222e` | `32608892328` |
| ReleaseGuard | `8e0d7e8c9feea59e389500713a1c3a0e2bfe17b0` | `32608895276` |
| Open Suite | `fb1d413f1e6423351b0db100388c7616d9bffcc4` | `32609612650` |

All six `v1.0.0-rc.2` releases are immutable GitHub prereleases. Their combined 70 attested subjects passed GitHub provenance verification. All 59 component release assets and all 10 checksummed suite artifacts passed their published SHA-256 manifests.

## Blockers found and resolved

The earlier `v1.0.0-rc.1` releases remain available for audit and were not changed.

1. The suite bootstrap completed installation but did not explicitly run `doctor`. RC2 executes the health gate after startup and fails installation acceptance when the suite is unhealthy.
2. Standalone product archives used generic binary names while their external release checksum files named raw platform binaries. RC2 archives now contain an internal checksum for the generic executable, and each external checksum continues to verify the downloaded archive or raw asset.

The corrected standalone packaging commits passed their normal CI before RC2 was tagged. A public Windows bootstrap acceptance script was then executed successfully and added to the Open Suite CI syntax gate.

## Public Windows amd64 acceptance

- Clean online bootstrap from the immutable RC2 GitHub release: install, start, doctor, all five components, local Fleet Agent identity, purge, and cleanup passed.
- Full public offline bundle: install, runtime, doctor, forced interrupted-upgrade recovery, persistent ports, product-state preservation, tampered-backup rejection, rollback, data-preserving uninstall, purge, and missing-asset network-fallback rejection passed.
- Public v0.3.3 to RC2 upgrade: four real product data markers, Fleet token, and ports survived upgrade; rollback restored v0.3.3; the second upgrade to RC2 and final cleanup passed.
- All four standalone archives passed internal checksum, doctor, data-preserving uninstall, unconfirmed-purge rejection, exact purge, and cleanup.

## Public Linux amd64 acceptance

Tests ran through isolated `/tmp` paths and dynamic loopback ports on host 136. No SongYueGe path, process, port, container, or service was accessed or modified.

- Clean online bootstrap from the immutable RC2 GitHub release passed install, start, doctor, all five components, Fleet Agent identity, purge, and cleanup.
- Full public offline bundle passed its public checksum, install, runtime, doctor, interrupted-upgrade recovery, failed-commit restoration, product-state preservation, tampered-backup rejection, rollback, data-preserving uninstall, purge, and missing-asset network-fallback rejection.
- Public v0.3.3 to RC2 upgrade preserved all four product data markers, Fleet token, and ports; rollback restored v0.3.3; final cleanup passed.
- All four standalone archives passed internal checksum, doctor, Fleet runtime health, data-preserving uninstall, purge guards, module ownership isolation, and cleanup.

The host did not permit an unprivileged network namespace during this RC2 run. The same no-network installer path remains covered by the earlier M1 namespace gate, while RC2 additionally proved that a missing offline asset cannot silently fall back to the network.

## Support boundary

Windows amd64 and Linux amd64 are the only native runtime-verified GA candidates. Linux arm64, macOS amd64, and macOS arm64 bundles passed build, archive, manifest, and checksum verification but remain build-tested previews. No macOS or arm64 native-runtime claim is made.

## GA decision

No RC2 release blocker remains. The next gate is to publish component/spec `v1.0.0` releases from the exact reviewed commits, assemble the stable suite manifest from the newly published GA digests, publish Open Suite `v1.0.0`, and repeat the public Windows/Linux smoke paths against the final immutable assets.
