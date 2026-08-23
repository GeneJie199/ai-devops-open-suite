# Compatibility Matrix

Updated: 2026-08-23

## Current stable suite

| Open Suite | lifecycle-spec | DevCycle | InfraScout | FleetScope | ReleaseGuard |
|---:|---:|---:|---:|---:|---:|
| 1.0.0 | 1.0.0 | 1.0.0 | 1.0.0 | 1.0.0 | 1.0.0 |

The stable suite manifest is authoritative. Installers reject an inconsistent component set before replacing a working installation.

## Compatibility guarantees

- Existing `lifecycle-spec` v0.1 documents remain valid against their published schemas.
- A product encountering an unsupported protocol version fails with the document kind, received version, and supported versions. It does not reinterpret the document silently.
- v1 protocol documents are introduced as new versioned schemas. Breaking fields are not retrofitted into v0.1.
- Every persisted-data migration is idempotent, records its applied version, and runs only after a recoverable backup has succeeded.
- A failed migration leaves the previous binaries and data recoverable. Rollback does not pretend that newer data is readable by older code unless a reverse migration was explicitly tested.
- Product APIs may add fields and endpoints in a compatible release. Removing fields, changing meaning, or weakening validation requires a new protocol/API version and migration notes.

## Upgrade paths

| From | To | Current state |
|---|---|---|
| Open Suite 0.3.3 / components 0.3.2 | v1.0.0 | verified on public Windows amd64 and Linux amd64 assets; rollback to 0.3.3 verified |
| v1.0.0-rc.2 | v1.0.0 | release manifests and clean installation verified |
| v1.0.0 | later v1 patch | must preserve v1 contracts |

Upgrade creates an integrity-checked backup before binary replacement. Ports, Fleet identity/token, DevCycle state, InfraScout state, Fleet registration, ReleaseGuard reports, and digest-bound approvals survived the accepted v0.3.3 upgrade path.

## Independent-product operation

Each product remains independently installable and operable. Cross-product integrations use:

- versioned JSON artifacts;
- documented HTTP APIs;
- lifecycle-spec schemas;
- explicit credentials or local files selected by the user.

Products do not import another product's internal packages or read another product's private database.
