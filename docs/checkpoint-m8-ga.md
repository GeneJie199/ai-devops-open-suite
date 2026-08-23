# M8 GA and Post-Release Checkpoint

Date: 2026-08-23
Result: PASS
Stable release: `v1.0.0`

## Publication

Five component/spec releases were built from the exact RC2-reviewed commits. The stable suite manifest was assembled from the newly published GA digests, passed CI `32612512050`, and was tagged at Open Suite commit `076be4e153e64c919870950fe7b67b9ff38e5ab9`. Open Suite release workflow `32612562754` completed successfully and `releases/latest` resolves to `v1.0.0`.

Across the six stable releases, 71 public assets were published. After redownload, all 64 checksum-listed artifacts passed SHA-256 and all 70 attested subjects passed GitHub provenance verification. Each release is non-draft and non-prerelease. RC1 and RC2 remain immutable audit records.

## Windows amd64

- Literal public README bootstrap from `main` and `releases/latest`: version 1.0.0, five components, four ready UIs, Fleet Agent identity, doctor, purge, cleanup.
- Public full offline bundle: 21-file manifest, no-fallback install, start, UI/Agent, doctor, interrupted-upgrade recovery, persistent ports and product state, tampered-backup rejection, rollback, data-preserving uninstall, exact purge.
- Public v0.3.3 launcher to v1.0.0: four product data markers, Fleet token, and ports preserved; rollback restored v0.3.3; second v1.0.0 upgrade and cleanup passed.

## Linux amd64

- Literal public README bootstrap from `main` and `releases/latest`: version 1.0.0, five components, four ready UIs, Fleet Agent identity, doctor, purge, cleanup.
- Public full offline bundle: checksum and 21-file manifest verified; install inside a no-network namespace passed; runtime, UI/Agent, doctor, interrupted recovery, failed-commit restoration, product-state preservation, tampered-backup rejection, rollback, uninstall, purge, and missing-asset fallback rejection passed.
- Public v0.3.3 launcher to v1.0.0 preserved product markers, Fleet token, and ports; rollback restored v0.3.3; second upgrade and cleanup passed.
- All four standalone product archives passed internal checksums, doctor, Fleet runtime health, data-preserving uninstall, purge confirmation, ownership isolation, and cleanup.

Host 136 tests stayed inside randomized `/tmp/ai-devops-*` roots and dynamic loopback ports. They did not enumerate or modify SongYueGe.

## Final decision

All M8 tasks and v1.0 acceptance gates passed. Windows amd64 and Linux amd64 are Verified; the other published architecture bundles remain Build tested. No patch release is required and no known blocker remains.
