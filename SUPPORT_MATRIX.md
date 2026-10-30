# Platform Support Matrix

Updated: 2026-08-23

Support levels:

- **Verified**: release artifacts have completed clean install and runtime acceptance on the named platform.
- **Build tested**: CI builds/tests the artifact, but no current native runtime acceptance is recorded.
- **Unsupported**: no release artifact or maintained execution path.

## Current stable release

| Platform | Artifact | Level | Evidence |
|---|---|---|---|
| Windows 11 amd64 | online and full offline | Verified | public v1.0.0 bootstrap, offline lifecycle, UI/Agent, v0.3.3 upgrade/rollback, uninstall/purge |
| Ubuntu 24.04 amd64 | online and full offline | Verified | public v1.0.0 bootstrap, no-network offline lifecycle, UI/Agent, standalone installers, v0.3.3 upgrade/rollback |
| Linux arm64 | online and full offline | Build tested | cross-build, archive, manifest, checksum, SBOM, and provenance only |
| macOS amd64 | online and full offline | Build tested | cross-build, archive, manifest, checksum, SBOM, and provenance only |
| macOS arm64 | online and full offline | Build tested | cross-build, archive, manifest, checksum, SBOM, and provenance only |
| Windows arm64 | none | Unsupported | current Windows installer rejects arm64 |

The v1.0.0 release includes one complete offline bundle for each advertised artifact platform. Every bundle contains all binaries, protocol files, installers, controllers, documentation, and an internal file manifest.

## v1.0 result

| Platform | Full offline bundle | GA level |
|---|---|---|
| Windows amd64 | published and verified | Verified |
| Linux amd64 | published and verified | Verified |
| Linux arm64 | published and structurally verified | Build tested |
| macOS amd64 | published and structurally verified | Build tested |
| macOS arm64 | published and structurally verified | Build tested |

An artifact may be published without being labeled Verified. README and release notes must preserve that distinction.

## Runtime boundaries

- Web services bind to loopback by default.
- Linux provides the richest InfraScout host discovery. Non-Linux products may run, but InfraScout collector coverage is not claimed as Linux-equivalent.
- The suite is designed for a local user or small team boundary. Enterprise SSO, multi-tenancy, and SLA-backed high availability are outside v1.0.
- FleetScope v1.0 is measured and recommended for up to 100 nodes per Center. The 100-node, 8-metric, 60-second, 3-day run retained 3,456,000 samples and 43,200 events in roughly 271 MiB Go heap and 647 MiB disk, with roughly 216 MB/day projected growth. See [the full scale baseline](docs/scale-benchmark.md).
- The 100-node starting recommendation is 2 CPU, 2 GiB RAM, 5 GiB disk, 60-second collection, and 3-day retention. Larger fleets, higher-cardinality labels, and longer retention are not verified GA claims.

## v2.0.0-rc.1 scope

The RC is for trusted single-user local environments. Windows amd64 and Linux
amd64 are the first Suite offline bundle targets. The C0 source-integration
workflow performs native install, runtime health, doctor, recovery, tamper,
rollback and offline acceptance. Windows additionally verifies actual public
v1.0.0 upgrade, schema3 plus Team sidecar schema1, restart and binary rollback.
The release manifest and final evidence record exact revisions and acceptance.

Linux arm64 and both macOS architectures are cross-built component artifacts;
Suite offline bundles for these platforms are not published in this RC because
native Suite lifecycle acceptance has not been completed. No Windows arm64 claim
is made. Cross-compilation is not a native installation test.
