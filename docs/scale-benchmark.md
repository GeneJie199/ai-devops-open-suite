# FleetScope v1.0 Scale Baseline

Measured: 2026-08-23

This is a real single-Center baseline, not a capacity claim derived from unit tests. The benchmark uses FleetScope's production telemetry and event stores, durable daily segments, sequence tracking, a cold restart, and a real query. It is reproducible with `fleetctl bench`.

## Workload

| Input | Value |
|---|---:|
| Nodes | 100 |
| Metrics per node | 8 |
| Metric interval | 60 seconds |
| Simulated retention | 3 days |
| Telemetry samples | 3,456,000 |
| Events | 43,200 |
| Store shape | production NDJSON segments plus sequence state |

## Results

| Measurement | Windows 11 amd64 | Ubuntu 24.04 amd64 on isolated host 136 |
|---|---:|---:|
| CPU | Intel i5-1035G1, 4 cores / 8 threads | Intel Celeron 5205U, 2 cores |
| Installed memory | 15.8 GiB | 7.6 GiB |
| Benchmark wall time | 245.509 s | 67.820 s |
| Process CPU time | 156.297 s | 60.060 s |
| Average CPU utilization | 0.637 core | 0.886 core |
| Telemetry ingest | 21,959 samples/s | 109,166 samples/s |
| Event ingest | 3,837 events/s | 12,202 events/s |
| Cold restart | 74.281 s | 31.527 s |
| Representative query | 1.331 s | 0.841 s |
| Go heap allocated after load | 271,032,168 B | 270,862,160 B |
| Go heap in use | 282,796,032 B | 282,714,112 B |
| Go system memory | 346,140,672 B | 368,347,496 B |
| Peak resident set | 346,030,080 B | 350,200 KiB |
| Telemetry disk | 634,698,403 B | 634,698,403 B |
| Event disk | 11,825,483 B | 11,825,483 B |
| Estimated disk growth per day | 215,507,962 B | 215,507,962 B |

The large OS throughput difference is attributed to storage and scheduler differences on the measured hosts; it is not interpreted as a general Windows/Linux ratio. Disk results match because both runs produced the same serialized workload.

## Recommendation

| Fleet size | Default interval | Default in-memory/history window | Minimum starting resource |
|---|---:|---:|---:|
| 1-25 nodes | 30 seconds | 7 days | 2 CPU, 2 GiB RAM, 5 GiB disk |
| 26-50 nodes | 60 seconds | 7 days | 2 CPU, 2 GiB RAM, 5 GiB disk |
| 51-100 nodes | 60 seconds | 3 days | 2 CPU, 2 GiB RAM, 5 GiB disk |

The v1.0 verified recommendation stops at **100 nodes per Center**. Deployments above 100 nodes, retention beyond the table, high-cardinality custom labels, and sustained event rates materially above this workload require a local benchmark and are not a GA support claim.

## Hardening Result

The first 100-node run exposed repeated metric metadata in every in-memory point. FleetScope was refactored to retain series metadata once and compact each point to timestamp/value, reducing loaded heap from roughly 1.598 GiB to roughly 271 MiB. Telemetry and event memory caps now retain a rolling newest window rather than refusing fresh observations. Durable time retention continues to prune segment files separately.

## Isolation

Host 136 used only randomized `/tmp/fleetscope-m7-scale.*` directories and loopback-only execution. No business mount, existing service, or SongYueGe test environment was enumerated, modified, or restarted. The temporary directories were removed and their absence verified after the run.
