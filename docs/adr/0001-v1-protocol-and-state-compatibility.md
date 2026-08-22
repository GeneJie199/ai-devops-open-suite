# ADR 0001: Additive v1 Protocol and Backup-First State Migration

Status: Accepted  
Date: 2026-08-22

## Context

The v0.3 products persist SQLite databases, JSON/NDJSON state, credentials, configuration, snapshots, approvals, run history, metric/event segments, and installation metadata. Cross-product artifacts use lifecycle-spec v0.1. v1.0 needs richer contracts without stranding existing users or coupling product internals.

## Decision

1. Keep lifecycle-spec v0.1 schemas immutable and valid.
2. Add v1 schemas beside v0.1 and identify each document with an explicit version.
3. Let products read every protocol version they explicitly list; reject unknown versions with an actionable error.
4. Keep product persistence private. Cross-product consumers use only public APIs/artifacts.
5. Give each persisted store a monotonic schema version and idempotent forward migrations.
6. Before the first state-changing migration, create a recoverable backup and atomically record install/migration state.
7. Treat binaries, configuration, and data separately during rollback. Binary rollback is always supported; data rollback is offered only from a recorded compatible backup and never discards newer user data implicitly.
8. Keep uninstall non-destructive by default. Data purge is a separate explicit action with a clear target path.

## Consequences

- v1 readers and validators carry explicit compatibility code for supported v0.1 inputs.
- Offline bundles include every schema, migration note, manifest, and compatible binary set required for the selected platform.
- Upgrade tests start from copied v0.3 state and cover interruption and rollback.
- New fields alone do not justify a breaking version; semantic changes and removals do.

## Rejected alternatives

- Rewriting v0.1 schemas in place: breaks immutable published contracts.
- Letting products read each other's databases: creates hidden coupling and unsafe migrations.
- Automatically purging incompatible state: violates the data-safety priority.
- Claiming older binaries can read newer data without tests: creates a false rollback guarantee.

