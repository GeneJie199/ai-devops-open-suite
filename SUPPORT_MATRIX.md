# Platform Support Matrix

Updated: 2026-08-23

Support levels:

- **Verified**: release artifacts have completed clean install and runtime acceptance on the named platform.
- **Build tested**: CI builds/tests the artifact, but no current native runtime acceptance is recorded.
- **Unsupported**: no release artifact or maintained execution path.

## Current stable release

| Platform | Artifact | Level | Evidence |
|---|---|---|---|
| Windows 11 amd64 | online component assets | Verified | v0.3.3 suite install/start/doctor/Agent/UI/stop |
| Linux amd64 | online component assets | Verified | isolated v0.3.3 install/runtime acceptance on host 136 |
| Linux arm64 | component assets | Build tested | GitHub Actions build only |
| macOS amd64 | component assets | Build tested | GitHub Actions build only |
| macOS arm64 | component assets | Build tested | GitHub Actions build only |
| Windows arm64 | none | Unsupported | current Windows installer rejects arm64 |

The current v0.3 release does not include a complete offline bundle. Its `--source-root` / `-SourceRoot` path is an offline installer mechanism that still requires the user to assemble matching assets.

## v1.0 target

| Platform | Full offline bundle | Planned GA level |
|---|---|---|
| Windows amd64 | required | Verified after public v1 smoke |
| Linux amd64 | required | Verified after public v1 smoke |
| Linux arm64 | required artifact | Build tested or Verified, based on native runtime evidence |
| macOS amd64 | required artifact | Build tested or Verified, based on native runtime evidence |
| macOS arm64 | required artifact | Build tested or Verified, based on native runtime evidence |

An artifact may be published without being labeled Verified. README and release notes must preserve that distinction.

## Runtime boundaries

- Web services bind to loopback by default.
- Linux provides the richest InfraScout host discovery. Non-Linux products may run, but InfraScout collector coverage is not claimed as Linux-equivalent.
- The suite is designed for a local user or small team boundary. Enterprise SSO, multi-tenancy, and SLA-backed high availability are outside v1.0.
- FleetScope v1.0 is measured and recommended for up to 100 nodes per Center. The 100-node, 8-metric, 60-second, 3-day run retained 3,456,000 samples and 43,200 events in roughly 271 MiB Go heap and 647 MiB disk, with roughly 216 MB/day projected growth. See [the full scale baseline](docs/scale-benchmark.md).
- The 100-node starting recommendation is 2 CPU, 2 GiB RAM, 5 GiB disk, 60-second collection, and 3-day retention. Larger fleets, higher-cardinality labels, and longer retention are not verified GA claims.
